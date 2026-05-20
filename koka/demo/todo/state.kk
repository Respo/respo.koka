module demo/todo/state

import demo/model
import runtime/dom
import respo/state

pub struct task_editor_state(editing : bool, draft : string)
pub alias todo_local_effect = <use_named_state,set_named_state,clear_local_state,use_named_effect,div>

pub fun task_hook_scope(item : task) : string
  "todo/tasks/" ++ task/id(item).show

pub fun todo_effect_scope() : string
  "todo/effects"

pub fun task_editing_slot(item : task) : state_slot
  hook_named_state_slot(task_hook_scope(item), "editing")

pub fun task_draft_slot(item : task) : state_slot
  hook_named_state_slot(task_hook_scope(item), "draft")

pub fun task_focus_effect_slot(item : task) : state_slot
  hook_named_effect_slot(task_hook_scope(item), "focus")

pub fun todo_draft_focus_slot() : state_slot
  hook_named_effect_slot(todo_effect_scope(), "draft-focus")

pub fun todo_notice_pulse_slot() : state_slot
  hook_named_effect_slot(todo_effect_scope(), "notice-pulse")

fun read_task_state(tree : list<state_entry>, item : task) : <div> task_editor_state
  Task_editor_state(
    state_value(tree, task_editing_slot(item), flag_state_codec, False),
    state_value(tree, task_draft_slot(item), text_state_codec, item.title))

pub fun use_task_editor(item : task) : <use_named_state,div> (task_editor_state, (bool) -> <set_named_state,div> (), (string) -> <set_named_state,div> ())
  val editing_slot = task_editing_slot(item)
  val draft_slot = task_draft_slot(item)
  val editing = use_named_state(editing_slot, flag_state_codec, False)
  val draft = use_named_state(draft_slot, text_state_codec, item.title)
  (Task_editor_state(editing, draft), fn(value) set_named_state(editing_slot, flag_state_codec, value), fn(value) set_named_state(draft_slot, text_state_codec, value))

pub fun use_task_focus(item : task, deps : list<string>, action : (string) -> io ()) : <use_named_effect,div> ()
  use_named_effect(task_focus_effect_slot(item), deps, action)

pub fun use_todo_panel_feedback(should_focus_draft : bool, should_pulse_notice : bool, notice : string, draft : string, total : int) : <use_named_effect,div> ()
  use_named_effect(todo_draft_focus_slot(), [notice, draft, total.show], fn(root_id) {
    if should_focus_draft then browser_focus(root_id, "draft") else ()
  })
  use_named_effect(todo_notice_pulse_slot(), [notice, total.show], fn(root_id) {
    if should_pulse_notice then browser_flash_marker(root_id, "todo-note", "effect-pulse") else ()
  })

pub fun start_task_editor(item : task) : <use_named_state,set_named_state,div> ()
  val (_editor, set_editing, set_draft) = use_task_editor(item)
  set_editing(True)
  set_draft(item.title)

pub fun update_task_editor_draft(item : task, draft : string) : <use_named_state,set_named_state,div> ()
  val (_editor, set_editing, set_draft) = use_task_editor(item)
  set_editing(True)
  set_draft(draft)

pub fun task_editor_draft(item : task) : <use_named_state,div> string
  val (editor, _set_editing, _set_draft) = use_task_editor(item)
  editor.draft

pub fun clear_task_editor(item : task) : <clear_local_state,div> ()
  clear_slot(task_editing_slot(item))
  clear_slot(task_draft_slot(item))

pub fun cancel_task_editor(item : task) : <use_named_state,set_named_state,clear_local_state,div> ()
  val (_editor, set_editing, set_draft) = use_task_editor(item)
  set_editing(False)
  set_draft(item.title)
  clear_task_editor(item)

pub fun clear_done_task_editors(tasks : list<task>) : <clear_local_state,div> ()
  foreach(tasks, fn(item)
    if item.done then clear_task_editor(item) else ()
  )

pub fun commit_task_hooks(owner : model, action : () -> <todo_local_effect,push_hook_scope,pop_hook_scope,use_state,use_state_pair,use_effect|e> model) : <div|e> model
  val (next_model, next_tree, _pending_effects) = run_local_state(owner.todo_local_tree, action)
  next_model(todo_local_tree = next_tree)

pub fun commit_task_tree(owner : model, action : () -> <todo_local_effect,push_hook_scope,pop_hook_scope,use_state,use_state_pair,use_effect|e> model) : <div|e> model
  commit_task_hooks(owner, action)

pub fun snapshot_task_editor(owner : model, item : task) : <div> task_editor_state
  read_task_state(owner.todo_local_tree, item)