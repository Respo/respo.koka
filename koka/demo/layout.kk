module demo/layout

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
  el("header", "intro", [class_attr("panel intro-panel")], Nil, "", [
    el("div", "intro-top", [class_attr("intro-top")], Nil, "", [
      el("h1", "intro-title", [class_attr("page-title")], Nil, "Respo core + dense debug demo", Nil),
      el("span", "route-indicator", [class_attr("route-indicator")], Nil, "route: #" ++ model_route_name(item), Nil),
    ]),
    el("p", "intro-note", [class_attr("section-note")], Nil, "`respo/*` holds VDOM helpers; `demo/*` now includes a workflow lab with local state, staged waits, mocked server handlers, and route-level demos.", Nil),
  ])

fun overview_stage(item : model, results : list<test_result>) : <div> (model, vnode, list<scheduled_effect>, event_registry<model,browser_event_effect>)
  val (item_with_todo, todo_node, todo_effects, todo_handlers) = run_todo_panel(item)
  val (next_item, lab_node, lab_effects, lab_handlers) = run_lab_panel(item_with_todo)
  (next_item, el("div", "overview", [class_attr("overview-grid")], Nil, "", [
    el("div", "overview-main", [class_attr("overview-main")], Nil, "", [
      todo_node,
    ]),
    el("aside", "overview-side", [class_attr("overview-side")], Nil, "", [
      tests_panel(results),
    ]),
    el("div", "overview-wide", [class_attr("overview-wide")], Nil, "", [
      lab_node,
    ]),
    el("div", "overview-wide-effects", [class_attr("overview-wide")], Nil, "", [
      effects_panel(next_item, results),
    ]),
  ]), append_scheduled_effects(todo_effects, lab_effects), append_event_registries(todo_handlers, lab_handlers))

fun route_stage(item : model, results : list<test_result>) : <div> (model, vnode, list<scheduled_effect>, event_registry<model,browser_event_effect>)
  if model_route_name(item) == "todo" then
    val (next_item, todo_node, pending_effects, handlers) = run_todo_panel(item)
    (next_item, el("div", "todo-stage", [class_attr("single-stage")], Nil, "", [todo_node]), pending_effects, handlers)
  else if model_route_name(item) == "lab" then
    val (next_item, lab_node, pending_effects, handlers) = run_lab_panel(item)
    (next_item, el("div", "lab-stage", [class_attr("single-stage")], Nil, "", [lab_node]), pending_effects, handlers)
  else if model_route_name(item) == "effects" then
    (item, el("div", "effects-stage", [class_attr("single-stage")], Nil, "", [effects_panel(item, results)]), Nil, empty_event_registry())
  else if model_route_name(item) == "checks" then
    (item, el("div", "checks-stage", [class_attr("single-stage")], Nil, "", [tests_panel(results)]), Nil, empty_event_registry())
  else
    overview_stage(item, results)

pub fun render_layout(item : model, results : list<test_result>) : <div> (model, vnode, list<scheduled_effect>, event_registry<model,browser_event_effect>)
  val (next_item, stage_node, pending_effects, handlers) = route_stage(item, results)
  (next_item, el("section", "app", [class_attr("shell app-shell")], Nil, "", [
    intro_panel(item),
    route_bar(next_item),
    stage_node,
  ]), pending_effects, handlers)
