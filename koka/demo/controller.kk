module demo/controller

import demo/dialogs
import demo/labpanel
import demo/model
import demo/todopanel

pub fun dispatch_click(payload : string, item : model) : <confirm_action,audit,current_operator,wait_ms,fetch_lab_snapshot,post_lab_reply,now_label,request_bridge_resource,div> model
  match handle_todo_click(payload, item)
    Just(result) -> result
    Nothing ->
      match handle_lab_click(payload, item)
        Just(result) -> result
        Nothing ->
          match handle_dialog_click(payload, item)
            Just(result) -> result
            Nothing -> reduce_click(payload, item)

pub fun dispatch_input(channel : string, value : string, item : model) : <request_bridge_resource,div> model
  match handle_todo_input(channel, value, item)
    Just(result) -> result
    Nothing ->
      match handle_lab_input(channel, value, item)
        Just(result) -> result
        Nothing ->
          match handle_dialog_input(channel, value, item)
            Just(result) -> result
            Nothing -> reduce_input(channel, value, item)