module demo/todo/state

import demo/model
import respo/state

pub struct task_editor_state(editing : bool, draft : string)

pub fun task_hook_scope(item : task) : string
  "todo/tasks/" ++ task/id(item).show

pub fun todo_effect_scope() : string
  "todo/effects"

pub fun task_editing_slot(item : task) : state_slot
  hook_state_slot(task_hook_scope(item), 0)

pub fun task_draft_slot(item : task) : state_slot
  hook_state_slot(task_hook_scope(item), 1)

pub fun task_focus_effect_slot(item : task) : state_slot
  hook_effect_slot(task_hook_scope(item), 0)

pub fun todo_draft_focus_slot() : state_slot
  hook_effect_slot(todo_effect_scope(), 0)

pub fun todo_notice_pulse_slot() : state_slot
  hook_effect_slot(todo_effect_scope(), 1)

fun read_task_state(tree : list<state_entry>, item : task) : <div> task_editor_state
  Task_editor_state(
    state_value(tree, task_editing_slot(item), flag_state_codec, False),
    state_value(tree, task_draft_slot(item), text_state_codec, item.title))

pub fun commit_task_hooks(owner : model, action : () -> <use_named_state,set_named_state,clear_local_state,use_named_effect,push_hook_scope,pop_hook_scope,use_state,use_state_pair,use_effect,div|e> model) : <div|e> model
  val (next_model, next_tree, _pending_effects) = run_local_state(owner.todo_local_tree, action)
  set_todo_local_tree(next_model, next_tree)

pub fun commit_task_tree(owner : model, action : () -> <use_named_state,set_named_state,clear_local_state,use_named_effect,push_hook_scope,pop_hook_scope,use_state,use_state_pair,use_effect,div|e> model) : <div|e> model
  commit_task_hooks(owner, action)

pub fun snapshot_task_editor(owner : model, item : task) : <div> task_editor_state
  read_task_state(owner.todo_local_tree, item)