module demo/todo/state

import demo/model
import explore/react/state

pub struct task_editor_state(editing : bool, draft : string)
pub alias todo_local_effect = <local_state_write,hook_state,hook_effects,div>

fun task_component_key(item : task) : string
  task/id(item).show

fun read_task_state(tree : list<state_entry>, item : task) : <div> task_editor_state
  Task_editor_state(
    read_component_indexed_state(tree, "tasks", task_component_key(item), 0, flag_state_codec, False),
    read_component_indexed_state(tree, "tasks", task_component_key(item), 1, text_state_codec, item.title))

pub fun clear_task_editor(item : task) : <local_state_write,div> ()
  clear_component_local_state("tasks", task_component_key(item))

pub fun clear_done_task_editors(tasks : list<task>) : <local_state_write,div> ()
  foreach(tasks, fn(item)
    if item.done then clear_task_editor(item) else ()
  )

pub fun commit_task_hooks(owner : model, action : () -> <todo_local_effect,local_state_read,hook_scope|e> model) : <div|e> model
  val (next_model, next_tree, _pending_effects) = run_local_state(owner.app_local_tree, action)
  next_model(app_local_tree = next_tree)

pub fun commit_task_tree(owner : model, action : () -> <todo_local_effect,local_state_read,hook_scope|e> model) : <div|e> model
  commit_task_hooks(owner, action)

pub fun snapshot_task_editor(owner : model, item : task) : <div> task_editor_state
  read_task_state(owner.app_local_tree, item)