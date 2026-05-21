module demo/todopanel

import demo/model
import demo/todo/events
import demo/todo/view
import demo/todo/viewmodel
import respo/core
import respo/state

pub fun run_todo_panel(item : model) : <div> (model, vnode, list<scheduled_effect>, event_registry<model,browser_event_effect>)
  run_stateful_component(
    item,
    item.app_local_tree,
    fn(owner, next_tree) owner(app_local_tree = next_tree),
    fn(owner) render_todo_panel(owner, todo_panel_state_of(owner)))

pub fun todo_panel(item : model) : <div> vnode
  val (_next_item, panel_node, _pending_effects, _handlers) = run_todo_panel(item)
  panel_node
