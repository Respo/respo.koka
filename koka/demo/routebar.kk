module demo/routebar

import demo/model
import respo/core

fun route_button(label : string, route_name : string, active_route : string) : vnode
  val class_name = if active_route == route_name then "button route-tab route-tab-active" else "button route-tab"
  el("button", "route-" ++ route_name, [class_attr(class_name)], [click_listener("route-" ++ route_name)], label, Nil)

pub fun route_bar(item : model) : vnode
  el("nav", "route-bar", [class_attr("panel route-panel")], Nil, "", [
    el("div", "route-bar-body", [class_attr("route-bar")], Nil, "", [
      route_button("Overview", "overview", model_route_name(item)),
      route_button("Todo", "todo", model_route_name(item)),
      route_button("Lab", "lab", model_route_name(item)),
      route_button("Effects", "effects", model_route_name(item)),
      route_button("Checks", "checks", model_route_name(item)),
    ]),
  ])