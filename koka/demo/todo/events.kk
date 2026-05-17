module demo/todo/events

import demo/model
import demo/todo/state
import respo/core
import respo/state

pub type todo_action
  Add_task
  Set_filter(filter_name : string)
  Clear_completed
  Toggle_task(task_id : int)
  Remove_task(task_id : int)
  Start_task_edit(task_id : int)
  Save_task_edit(task_id : int)

pub fun todo_action_payload(action : todo_action) : string
  match action
    Add_task -> "add-task"
    Set_filter(filter_name) -> "set-filter-" ++ filter_name
    Clear_completed -> "clear-completed"
    Toggle_task(task_id) -> "toggle-" ++ task_id.show
    Remove_task(task_id) -> "remove-" ++ task_id.show
    Start_task_edit(task_id) -> "edit-" ++ task_id.show
    Save_task_edit(task_id) -> "save-" ++ task_id.show

pub fun dispatch_todo_click(action : todo_action) : listener
  click_listener(todo_action_payload(action))

pub fun dispatch_todo_enter(action : todo_action) : listener
  enter_listener(todo_action_payload(action))

fun append_tasks(tasks : list<task>, item : task) : <div> list<task>
  match tasks
    Nil -> [item]
    Cons(head, rest) -> Cons(head, append_tasks(rest, item))

fun rename_task(tasks : list<task>, target_id : int, title : string) : <div> list<task>
  match tasks
    Nil -> Nil
    Cons(item, rest) ->
      val next_rest = rename_task(rest, target_id, title)
      if task_id(item) == target_id then
        Cons(Task(task_id(item), title, task_done(item)), next_rest)
      else
        Cons(item, next_rest)

fun toggle_tasks(payload : string, tasks : list<task>) : <div> list<task>
  match tasks
    Nil -> Nil
    Cons(item, rest) ->
      val next_rest = toggle_tasks(payload, rest)
      if payload == task_toggle_id(item) then Cons(Task(task_id(item), task_title(item), not(task_done(item))), next_rest) else Cons(item, next_rest)

fun find_by_remove(payload : string, tasks : list<task>) : <div> maybe<task>
  match tasks
    Nil -> Nothing
    Cons(item, rest) -> if payload == task_remove_id(item) then Just(item) else find_by_remove(payload, rest)

fun remove_tasks(payload : string, tasks : list<task>) : <div> list<task>
  match tasks
    Nil -> Nil
    Cons(item, rest) -> if payload == task_remove_id(item) then rest else Cons(item, remove_tasks(payload, rest))

fun clear_completed_tasks(tasks : list<task>) : <div> list<task>
  match tasks
    Nil -> Nil
    Cons(item, rest) -> if task_done(item) then clear_completed_tasks(rest) else Cons(item, clear_completed_tasks(rest))

fun clear_done_local_state(tasks : list<task>) : <clear_local_state,div> ()
  match tasks
    Nil -> ()
    Cons(item, rest) -> {
      clear_done_local_state(rest)
      if task_done(item) then {
        clear_slot(task_editing_slot(item))
        clear_slot(task_draft_slot(item))
      } else ()
    }

fun find_task_draft_channel(channel : string, tasks : list<task>) : <div> maybe<int>
  match tasks
    Nil -> Nothing
    Cons(item, rest) -> if channel == task_draft_channel(item) then Just(task_id(item)) else find_task_draft_channel(channel, rest)

fun has_edit(payload : string, tasks : list<task>) : <div> bool
  match tasks
    Nil -> False
    Cons(item, rest) -> if payload == task_edit_id(item) then True else has_edit(payload, rest)

fun has_save(payload : string, tasks : list<task>) : <div> bool
  match tasks
    Nil -> False
    Cons(item, rest) -> if payload == task_save_id(item) then True else has_save(payload, rest)

fun has_cancel(payload : string, tasks : list<task>) : <div> bool
  match tasks
    Nil -> False
    Cons(item, rest) -> if payload == task_cancel_id(item) then True else has_cancel(payload, rest)

fun task_id_from_edit(payload : string, tasks : list<task>) : <div> maybe<int>
  match tasks
    Nil -> Nothing
    Cons(item, rest) -> if payload == task_edit_id(item) then Just(task_id(item)) else task_id_from_edit(payload, rest)

fun task_id_from_save(payload : string, tasks : list<task>) : <div> maybe<int>
  match tasks
    Nil -> Nothing
    Cons(item, rest) -> if payload == task_save_id(item) then Just(task_id(item)) else task_id_from_save(payload, rest)

fun task_id_from_cancel(payload : string, tasks : list<task>) : <div> maybe<int>
  match tasks
    Nil -> Nothing
    Cons(item, rest) -> if payload == task_cancel_id(item) then Just(task_id(item)) else task_id_from_cancel(payload, rest)

fun task_id_from_toggle(payload : string, tasks : list<task>) : <div> maybe<int>
  match tasks
    Nil -> Nothing
    Cons(item, rest) -> if payload == task_toggle_id(item) then Just(task_id(item)) else task_id_from_toggle(payload, rest)

fun task_id_from_remove(payload : string, tasks : list<task>) : <div> maybe<int>
  match tasks
    Nil -> Nothing
    Cons(item, rest) -> if payload == task_remove_id(item) then Just(task_id(item)) else task_id_from_remove(payload, rest)

fun todo_add_task(owner : model) : <audit,div> model
  if model_draft(owner) == "" then
    set_notice(owner, "Draft is empty. Type something before adding.")
  else {
    audit("Added task: " ++ model_draft(owner))
    val next_task = Task(model_next_id(owner), model_draft(owner), False)
    val with_task = set_tasks(owner, append_tasks(model_tasks(owner), next_task))
    val with_draft = set_draft(with_task, "")
    val with_next_id = set_next_id(with_draft, model_next_id(owner) + 1)
    set_notice(with_next_id, "Added a new task from the Koka store.")
  }

fun todo_start_task_edit(owner : model, target_id : int) : <audit,use_named_state,set_named_state,div> model
  match find_task_by_id(target_id, model_tasks(owner))
    Nothing -> set_notice(owner, "Task not found for local editing.")
    Just(found) -> {
      val (_editing, set_editing) = use_named_state_pair(task_editing_slot(found), flag_state_codec, False)
      val (_draft, set_draft) = use_named_state_pair(task_draft_slot(found), text_state_codec, task_title(found))
      audit("Opened local edit state for task #" ++ target_id.show)
      set_editing(True)
      set_draft(task_title(found))
      set_notice(owner, "Editing task locally before committing the title.")
    }

fun todo_set_task_edit_draft(owner : model, target_id : int, draft : string) : <use_named_state,set_named_state,div> model
  match find_task_by_id(target_id, model_tasks(owner))
    Nothing -> set_notice(owner, "Task edit draft target was missing.")
    Just(found) -> {
      val (_editing, set_editing) = use_named_state_pair(task_editing_slot(found), flag_state_codec, False)
      val (_current_draft, set_draft) = use_named_state_pair(task_draft_slot(found), text_state_codec, task_title(found))
      set_editing(True)
      set_draft(draft)
      owner
    }

fun todo_cancel_task_edit(owner : model, target_id : int) : <use_named_state,set_named_state,clear_local_state,div> model
  match find_task_by_id(target_id, model_tasks(owner))
    Nothing -> set_notice(owner, "Task cancel target was missing.")
    Just(found) -> {
      val (_editing, set_editing) = use_named_state_pair(task_editing_slot(found), flag_state_codec, False)
      val (_draft, set_draft) = use_named_state_pair(task_draft_slot(found), text_state_codec, task_title(found))
      set_editing(False)
      set_draft(task_title(found))
      clear_slot(task_editing_slot(found))
      clear_slot(task_draft_slot(found))
      set_notice(owner, "Cancelled local task edit.")
    }

fun todo_save_task_edit(owner : model, target_id : int) : <use_named_state,set_named_state,clear_local_state,audit,div> model
  match find_task_by_id(target_id, model_tasks(owner))
    Nothing -> set_notice(owner, "Task not found while saving the local edit.")
    Just(found) -> {
      val (_editing, set_editing) = use_named_state_pair(task_editing_slot(found), flag_state_codec, False)
      val draft = use_named_state(task_draft_slot(found), text_state_codec, task_title(found))
      if draft == "" then
        set_notice(owner, "Task title cannot be empty.")
      else {
        audit("Saved local task edit for #" ++ target_id.show)
        set_editing(False)
        clear_slot(task_editing_slot(found))
        clear_slot(task_draft_slot(found))
        val renamed = set_tasks(owner, rename_task(model_tasks(owner), target_id, draft))
        set_notice(renamed, "Saved task title from local state.")
      }
    }

fun todo_handle_toggle(owner : model, payload : string) : <audit,div> model
  audit("Toggled task state from the Koka reducer.")
  set_notice(set_tasks(owner, toggle_tasks(payload, model_tasks(owner))), "Toggled a task.")

fun todo_handle_remove(owner : model, payload : string) : <confirm_action,audit,clear_local_state,div> model
  match find_by_remove(payload, model_tasks(owner))
    Nothing -> set_notice(owner, "Task not found for removal.")
    Just(found) ->
      if confirm_action("Remove `" ++ task_title(found) ++ "`?") then {
        audit("Removed task after confirmation: " ++ task_title(found))
        clear_slot(task_editing_slot(found))
        clear_slot(task_draft_slot(found))
        val next = set_tasks(owner, remove_tasks(payload, model_tasks(owner)))
        set_notice(next, "Task removed after confirm effect.")
      } else
        set_notice(owner, "Removal cancelled by confirm effect.")

fun todo_handle_clear_completed(owner : model) : <confirm_action,audit,clear_local_state,div> model
  if not(has_done_tasks(model_tasks(owner))) then
    set_notice(owner, "There are no completed tasks to clear.")
  else if confirm_action("Clear every completed task?") then {
    audit("Cleared completed tasks.")
    clear_done_local_state(model_tasks(owner))
    val next = set_tasks(owner, clear_completed_tasks(model_tasks(owner)))
    set_notice(next, "Completed tasks cleared after confirm effect.")
  } else
    set_notice(owner, "Clear completed cancelled.")

pub fun dispatch_todo_action(action : todo_action, owner : model) : <confirm_action,audit,div> model
  match action
    Add_task -> commit_task_hooks(owner, fn() todo_add_task(owner))
    Set_filter(filter_name) -> set_filter(owner, filter_name)
    Clear_completed -> commit_task_hooks(owner, fn() todo_handle_clear_completed(owner))
    Toggle_task(task_id) -> todo_handle_toggle(owner, task_toggle_id(Task(task_id, "", False)))
    Remove_task(task_id) -> commit_task_hooks(owner, fn() todo_handle_remove(owner, task_remove_id(Task(task_id, "", False))))
    Start_task_edit(task_id) -> commit_task_hooks(owner, fn() todo_start_task_edit(owner, task_id))
    Save_task_edit(task_id) -> commit_task_hooks(owner, fn() todo_save_task_edit(owner, task_id))

fun decode_todo_action(payload : string, owner : model) : <div> maybe<todo_action>
  if payload == "add-task" then
    Just(Add_task)
  else if payload == "set-filter-all" then
    Just(Set_filter("all"))
  else if payload == "set-filter-active" then
    Just(Set_filter("active"))
  else if payload == "set-filter-done" then
    Just(Set_filter("done"))
  else if payload == "clear-completed" then
    Just(Clear_completed)
  else if has_toggle(payload, model_tasks(owner)) then
    match task_id_from_toggle(payload, model_tasks(owner))
      Just(task_id) -> Just(Toggle_task(task_id))
      Nothing -> Nothing
  else if has_remove(payload, model_tasks(owner)) then
    match task_id_from_remove(payload, model_tasks(owner))
      Just(task_id) -> Just(Remove_task(task_id))
      Nothing -> Nothing
  else if has_edit(payload, model_tasks(owner)) then
    match task_id_from_edit(payload, model_tasks(owner))
      Just(task_id) -> Just(Start_task_edit(task_id))
      Nothing -> Nothing
  else if has_save(payload, model_tasks(owner)) then
    match task_id_from_save(payload, model_tasks(owner))
      Just(task_id) -> Just(Save_task_edit(task_id))
      Nothing -> Nothing
  else
    Nothing

pub fun route_todo_click(payload : string, owner : model) : <confirm_action,audit,div> maybe<model>
  match decode_todo_action(payload, owner)
    Just(action) -> Just(dispatch_todo_action(action, owner))
    Nothing -> {
      if has_cancel(payload, model_tasks(owner)) then
        match task_id_from_cancel(payload, model_tasks(owner))
          Just(target_id) -> Just(commit_task_tree(owner, fn() todo_cancel_task_edit(owner, target_id)))
          Nothing -> Just(set_notice(owner, "Task cancel target was missing."))
      else
        Nothing
    }

pub fun route_todo_input(channel : string, value : string, owner : model) : <div> maybe<model>
  if channel == "draft" then
    Just(set_draft(owner, value))
  else
    match find_task_draft_channel(channel, model_tasks(owner))
      Just(target_id) -> Just(commit_task_tree(owner, fn() todo_set_task_edit_draft(owner, target_id, value)))
      Nothing -> Nothing