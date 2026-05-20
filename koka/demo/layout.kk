module demo/layout

import demo/dialogs
import demo/model
import demo/tests/support
import demo/routebar
import demo/todopanel
import demo/labpanel
import demo/effectspanel
import demo/testspanel
import respo/core
import respo/state

fun intro_panel(item : model) : <div> vnode
  node_class("header", "intro", "panel intro-panel", [
    node_class("div", "intro-top", "intro-top", [
      text_class("h1", "intro-title", "page-title", "Respo core + dense debug demo"),
      text_class("span", "route-indicator", "route-indicator", "route: #" ++ model_route_name(item)),
    ]),
    text_class("p", "intro-note", "section-note", "`respo/*` holds VDOM helpers; `demo/*` now exposes finer subroutes so search, bridge, dialogs, workflow, and timing demos are easier to inspect in isolation."),
  ])

fun overview_stage(item : model, results : list<test_result>) : <div> (model, vnode, list<scheduled_effect>, event_registry<model,browser_event_effect>)
  val (item_with_todo, todo_node, todo_effects, todo_handlers) = run_todo_panel(item)
  val (next_item, lab_node, lab_effects, lab_handlers) = run_lab_panel(item_with_todo)
  (next_item, node_class("div", "overview", "overview-grid", [
    node_class("div", "overview-main", "overview-main", [
      todo_node,
    ]),
    node_class("aside", "overview-side", "overview-side", [
      tests_panel(results),
    ]),
    node_class("div", "overview-wide", "overview-wide", [
      lab_node,
    ]),
    node_class("div", "overview-wide-effects", "overview-wide", [
      effects_panel(next_item, results),
    ]),
  ]), append_scheduled_effects(todo_effects, lab_effects), append_event_registries(todo_handlers, lab_handlers))

fun route_stage(item : model, results : list<test_result>) : <div> (model, vnode, list<scheduled_effect>, event_registry<model,browser_event_effect>)
  if model_route_name(item) == "todo" then
    val (next_item, todo_node, pending_effects, handlers) = run_todo_panel(item)
    (next_item, node_class("div", "todo-stage", "single-stage", [todo_node]), pending_effects, handlers)
  else if route_is_lab(model_route_name(item)) then
    val (next_item, lab_node, pending_effects, handlers) = run_lab_panel(item)
    (next_item, node_class("div", "lab-stage", "single-stage", [lab_node]), pending_effects, handlers)
  else if route_is_effects(model_route_name(item)) then
    (item, node_class("div", "effects-stage", "single-stage", [effects_panel(item, results)]), Nil, empty_event_registry())
  else if model_route_name(item) == "checks" then
    (item, node_class("div", "checks-stage", "single-stage", [tests_panel(results)]), Nil, empty_event_registry())
  else
    overview_stage(item, results)

pub fun render_layout(item : model, results : list<test_result>) : <div> (model, vnode, list<scheduled_effect>, event_registry<model,browser_event_effect>)
  val (next_item, stage_node, pending_effects, handlers) = route_stage(item, results)
  val dialog_effects = dialog_pending_effects(next_item)
  val shell_children = if dialog_is_open(model_dialog(next_item)) then
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
  (next_item, node_class("section", "app", "shell app-shell", shell_children), append_scheduled_effects(pending_effects, dialog_effects), handlers)
