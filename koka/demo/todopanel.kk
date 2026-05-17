module demo/todopanel

import demo/model
import demo/todo/events
import demo/todo/state
import demo/todo/view
import respo/core

pub fun task_editor_snapshot(owner : model, item : task) : <div> task_editor_state
  snapshot_task_editor(owner, item)

pub fun todo_panel(item : model) : <div> vnode
  render_todo_panel(item)

pub fun handle_todo_click(payload : string, owner : model) : <confirm_action,audit,div> maybe<(model, maybe<string>)>
  route_todo_click(payload, owner)

pub fun handle_todo_input(channel : string, value : string, owner : model) : <div> maybe<model>
  route_todo_input(channel, value, owner)
