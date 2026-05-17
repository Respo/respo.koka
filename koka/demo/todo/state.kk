module demo/todo/state

import demo/model
import respo/state

pub struct task_editor_state(editing : bool, draft : string)

pub fun task_editor_editing(item : task_editor_state) : bool
  match item
    Task_editor_state(editing, _) -> editing

pub fun task_editor_draft(item : task_editor_state) : string
  match item
    Task_editor_state(_, draft) -> draft

fun task_state_base(item : task) : string
  "todo/tasks/" ++ task_id(item).show

fun todo_effect_base() : string
  "todo/effects"

pub fun task_editing_slot(item : task) : state_slot
  named_slot(task_state_base(item), "editing")

pub fun task_draft_slot(item : task) : state_slot
  named_slot(task_state_base(item), "draft")

pub fun task_focus_effect_slot(item : task) : state_slot
  named_slot(task_state_base(item), "focus-effect")

pub fun todo_draft_focus_slot() : state_slot
  named_slot(todo_effect_base(), "draft-focus")

pub fun todo_notice_pulse_slot() : state_slot
  named_slot(todo_effect_base(), "notice-pulse")

fun read_task_state(tree : list<state_entry>, item : task) : <div> task_editor_state
  Task_editor_state(
    state_value(tree, task_editing_slot(item), flag_state_codec, False),
    state_value(tree, task_draft_slot(item), text_state_codec, task_title(item)))

pub fun task_editor(item : task) : <use_state,div> task_editor_state
  Task_editor_state(
    use_state(task_editing_slot(item), flag_state_codec, False),
    use_state(task_draft_slot(item), text_state_codec, task_title(item)))

pub fun write_task_editor(item : task, next : task_editor_state) : <set_state,div> ()
  set_state(task_editing_slot(item), flag_state_codec, task_editor_editing(next))
  set_state(task_draft_slot(item), text_state_codec, task_editor_draft(next))

pub fun clear_task_editor(item : task) : <clear_local_state,div> ()
  clear_slot(task_editing_slot(item))
  clear_slot(task_draft_slot(item))

pub fun commit_task_hooks(owner : model, action : () -> <use_state,set_state,clear_local_state,use_effect,div|e> model) : <div|e> model
  val (next_model, next_tree, _pending_effects) = run_local_state(model_todo_local_tree(owner), action)
  set_todo_local_tree(next_model, next_tree)

pub fun commit_task_tree(owner : model, action : () -> <use_state,set_state,clear_local_state,use_effect,div|e> model) : <div|e> model
  commit_task_hooks(owner, action)

pub fun snapshot_task_editor(owner : model, item : task) : <div> task_editor_state
  read_task_state(model_todo_local_tree(owner), item)