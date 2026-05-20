module demo/layout

import demo/dialogs
import demo/model
import demo/tests/support
import demo/routebar
import demo/todopanel
import demo/labpanel
import demo/effectspanel
import demo/testspanel
import library/dialog
import respo/core
import respo/state

fun intro_panel(item : model) : <div> vnode
  header([class_attr("panel intro-panel")], [
    div([class_attr("intro-top")], [
      h1([class_attr("page-title")], "Respo core + dense debug demo"),
      span([class_attr("route-indicator")], "route: #" ++ item.route_name),
    ]),
    p([class_attr("section-note")], "`respo/*` holds VDOM helpers; `demo/*` now exposes finer subroutes so search, bridge, dialogs, workflow, and timing demos are easier to inspect in isolation."),
  ])

fun overview_stage(item : model, results : list<test_result>) : <div> (model, vnode, list<scheduled_effect>, event_registry<model,browser_event_effect>)
  val (item_with_todo, todo_node, todo_effects, todo_handlers) = run_todo_panel(item)
  val (next_item, lab_node, lab_effects, lab_handlers) = run_lab_panel(item_with_todo)
  (next_item, div([class_attr("overview-grid")], [
    div([class_attr("overview-main")], [
      todo_node,
    ]),
    aside([class_attr("overview-side")], [
      tests_panel(results),
    ]),
    div([class_attr("overview-wide")], [
      lab_node,
    ]),
    div([class_attr("overview-wide")], [
      effects_panel(next_item, results),
    ]),
  ]), append_scheduled_effects(todo_effects, lab_effects), append_event_registries(todo_handlers, lab_handlers))

fun route_stage(item : model, results : list<test_result>) : <div> (model, vnode, list<scheduled_effect>, event_registry<model,browser_event_effect>)
  if item.route_name == "todo" then
    val (next_item, todo_node, pending_effects, handlers) = run_todo_panel(item)
    (next_item, div([class_attr("single-stage")], [todo_node]), pending_effects, handlers)
  else if route_is_lab(item.route_name) then
    val (next_item, lab_node, pending_effects, handlers) = run_lab_panel(item)
    (next_item, div([class_attr("single-stage")], [lab_node]), pending_effects, handlers)
  else if route_is_effects(item.route_name) then
    (item, div([class_attr("single-stage")], [effects_panel(item, results)]), Nil, empty_event_registry())
  else if item.route_name == "checks" then
    (item, div([class_attr("single-stage")], [tests_panel(results)]), Nil, empty_event_registry())
  else
    overview_stage(item, results)

pub fun render_layout(item : model, results : list<test_result>) : <div> (model, vnode, list<scheduled_effect>, event_registry<model,browser_event_effect>)
  val (next_item, stage_node, pending_effects, handlers) = route_stage(item, results)
  val dialog_effects = dialog_pending_effects(next_item)
  val shell_children = if dialog_is_open(next_item.dialog) then
    [
      intro_panel(next_item),
      route_bar(next_item),
      stage_node,
      render_dialog_overlay(next_item),
    ]
  else
    [
      intro_panel(next_item),
      route_bar(next_item),
      stage_node,
    ]
  (next_item, section_key("app", [class_attr("shell app-shell")], shell_children), append_scheduled_effects(pending_effects, dialog_effects), handlers)
