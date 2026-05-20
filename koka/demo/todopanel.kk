module demo/todopanel

import demo/model
import demo/todo/events
import demo/todo/state
import demo/todo/view
import respo/core
import respo/state

pub fun task_editor_snapshot(owner : model, item : task) : <div> task_editor_state
  snapshot_task_editor(owner, item)

pub fun run_todo_panel(item : model) : <div> (model, vnode, list<scheduled_effect>, event_registry<model,browser_event_effect>)
  val ((panel_node, next_tree, pending_effects), handlers) = run_event_registry(fn() run_local_state(item.todo_local_tree, fn() render_todo_panel(item)))
  (set_todo_local_tree(item, next_tree), panel_node, pending_effects, handlers)

pub fun todo_panel(item : model) : <div> vnode
  val (_next_item, panel_node, _pending_effects, _handlers) = run_todo_panel(item)
  panel_node

pub fun handle_todo_click(payload : string, owner : model) : <confirm_action,audit,div> maybe<model>
  route_todo_click(payload, owner)

pub fun handle_todo_input(channel : string, value : string, owner : model) : <div> maybe<model>
  route_todo_input(channel, value, owner)
