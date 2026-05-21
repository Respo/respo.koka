module demo/controller

import demo/dialogs
import demo/labpanel
import demo/model
import demo/todopanel
import library/bridge
import library/maybe

fun resolve_click(payload : string, item : model) : <confirm_action,audit,current_operator,wait_ms,fetch_lab_snapshot,post_lab_reply,now_label,request_bridge_resource,div> maybe<model>
  handle_todo_click(payload, item).or-else {
    handle_lab_click(payload, item).or-else {
      handle_dialog_click(payload, item).or-else {
        handle_route_click(payload, item)
      }
    }
  }

pub fun dispatch_click(payload : string, item : model) : <confirm_action,audit,current_operator,wait_ms,fetch_lab_snapshot,post_lab_reply,now_label,request_bridge_resource,div> model
  resolve_click(payload, item).unwrap-or-else {
    reduce_click(payload, item)
  }

fun resolve_input(channel : string, value : string, item : model) : <request_bridge_resource,div> maybe<model>
  handle_todo_input(channel, value, item).or-else {
    handle_lab_input(channel, value, item)
  }

pub fun dispatch_input(channel : string, value : string, item : model) : <request_bridge_resource,div> model
  resolve_input(channel, value, item).unwrap-or-else {
    reduce_input(channel, value, item)
  }