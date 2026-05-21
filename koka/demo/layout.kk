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
import library/route
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

fun wrap_single_stage(node : vnode) : vnode
  div([class_attr("single-stage")], [node])

fun overview_stage(item : model, results : list<test_result>) : <div> (model, vnode, list<scheduled_effect>, event_registry<model,browser_event_effect>)
  val (effects_item, ((todo_node, lab_node), effects_node), effects, handlers) = compose_component_runs(
    compose_component_runs(
      run_todo_panel(item),
      run_lab_panel),
    fn(next_item) run_effects_panel(next_item, results))
  (effects_item, div([class_attr("overview-grid")], [
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
      effects_node,
    ]),
  ]), effects, handlers)

fun route_stage(item : model, results : list<test_result>) : <div> (model, vnode, list<scheduled_effect>, event_registry<model,browser_event_effect>)
  if item.route_name == "todo" then
    map_component_run(run_todo_panel(item), fn(_next_item, todo_node) wrap_single_stage(todo_node))
  else if route_is_lab(item.route_name) then
    map_component_run(run_lab_panel(item), fn(_next_item, lab_node) wrap_single_stage(lab_node))
  else if route_is_effects(item.route_name) then
    map_component_run(run_effects_panel(item, results), fn(_next_item, effects_node) wrap_single_stage(effects_node))
  else if item.route_name == "checks" then
    pure_component_run(item, wrap_single_stage(tests_panel(results)))
  else
    overview_stage(item, results)

pub fun render_layout(item : model, results : list<test_result>) : <current_hook_scope_name,register_listener<model,browser_event_effect>,div> (model, vnode, list<scheduled_effect>, event_registry<model,browser_event_effect>)
  val stage_run = route_stage(item, results)
  val (next_item, _stage_view, _pending_effects, _handlers) = stage_run
  if dialog_is_open(next_item.dialog) then
    map_component_run(
      compose_component_runs(stage_run, run_dialog_overlay),
      fn(dialog_item, stage_and_dialog) {
        val (next_stage_node, dialog_node) = stage_and_dialog
        section_key("app", [class_attr("shell app-shell")], [
          intro_panel(dialog_item),
          route_bar(dialog_item),
          next_stage_node,
          dialog_node,
        ])
      })
  else
    map_component_run(stage_run, fn(owner, current_stage) section_key("app", [class_attr("shell app-shell")], [
      intro_panel(owner),
      route_bar(owner),
      current_stage,
    ]))
