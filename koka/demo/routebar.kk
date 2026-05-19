module demo/routebar

import demo/model
import respo/core

fun route_button(label : string, route_name : string, active_route : string) : vnode
  val class_name = if active_route == route_name then "button route-tab route-tab-active" else "button route-tab"
  button_class("route-" ++ route_name, class_name, [click_listener("route-" ++ route_name)], label)

pub fun route_bar(item : model) : vnode
  node_class("nav", "route-bar", "panel route-panel", [
    node_class("div", "route-bar-body", "route-bar", [
      route_button("Overview", "overview", model_route_name(item)),
      route_button("Todo", "todo", model_route_name(item)),
      route_button("Lab", "lab", model_route_name(item)),
      route_button("Effects", "effects", model_route_name(item)),
      route_button("Checks", "checks", model_route_name(item)),
    ]),
  ])
