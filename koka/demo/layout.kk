module demo/layout

import demo/model
import demo/tests
import demo/routebar
import demo/todopanel
import demo/labpanel
import demo/effectspanel
import demo/testspanel
import respo/core

fun intro_panel(item : model) : <div> vnode
  el("header", "intro", [class_attr("panel intro-panel")], Nil, "", [
    el("div", "intro-top", [class_attr("intro-top")], Nil, "", [
      el("h1", "intro-title", [class_attr("page-title")], Nil, "Respo core + dense debug demo", Nil),
      el("span", "route-indicator", [class_attr("route-indicator")], Nil, "route: #" ++ model_route_name(item), Nil),
    ]),
    el("p", "intro-note", [class_attr("section-note")], Nil, "`respo/*` holds VDOM helpers; `demo/*` now includes a workflow lab with local state, staged waits, mocked server handlers, and route-level demos.", Nil),
  ])

fun overview_stage(item : model, results : list<test_result>) : <div> vnode
  el("div", "overview", [class_attr("overview-grid")], Nil, "", [
    el("div", "overview-main", [class_attr("overview-main")], Nil, "", [
      todo_panel(item),
    ]),
    el("aside", "overview-side", [class_attr("overview-side")], Nil, "", [
      tests_panel(results),
    ]),
    el("div", "overview-wide", [class_attr("overview-wide")], Nil, "", [
      lab_panel(item),
    ]),
    el("div", "overview-wide-effects", [class_attr("overview-wide")], Nil, "", [
      effects_panel(item, results),
    ]),
  ])

fun route_stage(item : model, results : list<test_result>) : <div> vnode
  if model_route_name(item) == "todo" then
    el("div", "todo-stage", [class_attr("single-stage")], Nil, "", [todo_panel(item)])
  else if model_route_name(item) == "lab" then
    el("div", "lab-stage", [class_attr("single-stage")], Nil, "", [lab_panel(item)])
  else if model_route_name(item) == "effects" then
    el("div", "effects-stage", [class_attr("single-stage")], Nil, "", [effects_panel(item, results)])
  else if model_route_name(item) == "checks" then
    el("div", "checks-stage", [class_attr("single-stage")], Nil, "", [tests_panel(results)])
  else
    overview_stage(item, results)

pub fun render_layout(item : model, results : list<test_result>) : <div> vnode
  el("section", "app", [class_attr("shell app-shell")], Nil, "", [
    intro_panel(item),
    route_bar(item),
    route_stage(item, results),
  ])
