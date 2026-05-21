module demo/todo/state

import demo/model
import respo/state

pub struct task_editor_state(editing : bool, draft : string)
pub alias todo_local_effect = <set_named_state,clear_local_state,use_state,use_state_pair,use_effect,div>

fun task_component_key(item : task) : string
  task/id(item).show

fun read_task_state(tree : list<state_entry>, item : task) : <div> task_editor_state
  Task_editor_state(
    read_component_named_state(tree, "tasks", task_component_key(item), "editing", flag_state_codec, False),
    read_component_named_state(tree, "tasks", task_component_key(item), "draft", text_state_codec, item.title))

pub fun clear_task_editor(item : task) : <clear_local_state,div> ()
  clear_component_local_state("tasks", task_component_key(item))

pub fun clear_done_task_editors(tasks : list<task>) : <clear_local_state,div> ()
  foreach(tasks, fn(item)
    if item.done then clear_task_editor(item) else ()
  )

pub fun commit_task_hooks(owner : model, action : () -> <todo_local_effect,use_named_state,use_named_effect,current_hook_scope_name,push_hook_scope,pop_hook_scope|e> model) : <div|e> model
  val (next_model, next_tree, _pending_effects) = run_local_state(owner.app_local_tree, action)
  next_model(app_local_tree = next_tree)

pub fun commit_task_tree(owner : model, action : () -> <todo_local_effect,use_named_state,use_named_effect,current_hook_scope_name,push_hook_scope,pop_hook_scope|e> model) : <div|e> model
  commit_task_hooks(owner, action)

pub fun snapshot_task_editor(owner : model, item : task) : <div> task_editor_state
  read_task_state(owner.app_local_tree, item)