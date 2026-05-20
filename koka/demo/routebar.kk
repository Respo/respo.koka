module demo/routebar

import demo/model
import library/route
import respo/core

fun route_button(label : string, route_name : string, active : bool) : vnode
  val class_name = if active then "button route-tab route-tab-active" else "button route-tab"
  button([class_attr(class_name)], [click_listener(route_action_payload(Navigate(route_name)))], label)

fun lab_subroutes(active_route : string) : vnode
  div([class_attr("route-bar route-sub-bar")], [
    route_button("Board", "lab-board", active_route == "lab-board"),
    route_button("Search", "lab-search", active_route == "lab-search"),
    route_button("Bridge", "lab-bridge", active_route == "lab-bridge"),
  ])

fun effects_subroutes(active_route : string) : vnode
  div([class_attr("route-bar route-sub-bar")], [
    route_button("Core", "effects-core", active_route == "effects-core"),
    route_button("Dialogs", "effects-dialogs", active_route == "effects-dialogs"),
    route_button("Workflow", "effects-workflow", active_route == "effects-workflow"),
    route_button("State", "effects-state", active_route == "effects-state"),
    route_button("Timer", "effects-timer", active_route == "effects-timer"),
  ])

pub fun route_bar(item : model) : vnode
  val active_route = item.route_name
  val active_section = route_section(active_route)
  val secondary_bar =
    if active_section == "lab" then lab_subroutes(active_route)
    else if active_section == "effects" then effects_subroutes(active_route)
    else div([class_attr("route-sub-bar route-sub-bar-empty")], Nil)
  nav_key("route-bar", [class_attr("panel route-panel")], [
    div([class_attr("route-bar")], [
      route_button("Overview", "overview", active_section == "overview"),
      route_button("Todo", "todo", active_section == "todo"),
      route_button("Lab", "lab", active_section == "lab"),
      route_button("Effects", "effects", active_section == "effects"),
      route_button("Checks", "checks", active_section == "checks"),
    ]),
    secondary_bar,
  ])
