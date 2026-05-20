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
  tasks ++ [item]

fun rename_task(tasks : list<task>, target_id : int, title : string) : <div> list<task>
  map(tasks, fn(item) if task/id(item) == target_id then item(title = title) else item)

fun toggle_tasks(payload : string, tasks : list<task>) : <div> list<task>
  map(tasks, fn(item) if payload == "toggle-" ++ task/id(item).show then item(done = not(item.done)) else item)

fun find_by_remove(payload : string, tasks : list<task>) : <div> maybe<task>
  find(tasks, fn(item) payload == "remove-" ++ task/id(item).show)

fun remove_tasks(payload : string, tasks : list<task>) : <div> list<task>
  filter(tasks, fn(item) payload != "remove-" ++ task/id(item).show)

fun clear_completed_tasks(tasks : list<task>) : <div> list<task>
  filter(tasks, fn(item) not(item.done))

fun clear_done_local_state(tasks : list<task>) : <clear_local_state,div> ()
  clear_done_task_editors(tasks)

fun find_task_draft_channel(channel : string, tasks : list<task>) : <div> maybe<int>
  match find(tasks, fn(item) channel == "task-draft-" ++ task/id(item).show)
    Just(item) -> Just(task/id(item))
    Nothing -> Nothing

fun task_id_from_edit(payload : string, tasks : list<task>) : <div> maybe<int>
  match find(tasks, fn(item) payload == "edit-" ++ task/id(item).show)
    Just(item) -> Just(task/id(item))
    Nothing -> Nothing

fun task_id_from_save(payload : string, tasks : list<task>) : <div> maybe<int>
  match find(tasks, fn(item) payload == "save-" ++ task/id(item).show)
    Just(item) -> Just(task/id(item))
    Nothing -> Nothing

fun task_id_from_cancel(payload : string, tasks : list<task>) : <div> maybe<int>
  match find(tasks, fn(item) payload == "cancel-" ++ task/id(item).show)
    Just(item) -> Just(task/id(item))
    Nothing -> Nothing

fun task_id_from_toggle(payload : string, tasks : list<task>) : <div> maybe<int>
  match find(tasks, fn(item) payload == "toggle-" ++ task/id(item).show)
    Just(item) -> Just(task/id(item))
    Nothing -> Nothing

fun task_id_from_remove(payload : string, tasks : list<task>) : <div> maybe<int>
  match find(tasks, fn(item) payload == "remove-" ++ task/id(item).show)
    Just(item) -> Just(task/id(item))
    Nothing -> Nothing

fun todo_add_task(owner : model) : <audit,div> model
  if owner.draft == "" then
    owner(notice = "Draft is empty. Type something before adding.")
  else {
    audit("Added task: " ++ owner.draft)
    val next_task = Task(owner.next_id, owner.draft, False)
    val with_task = owner(tasks = append_tasks(owner.tasks, next_task))
    val with_draft = with_task(draft = "")
    val with_next_id = with_draft(next_id = owner.next_id + 1)
    with_next_id(notice = "Added a new task from the Koka store.")
  }

fun todo_start_task_edit(owner : model, target_id : int) : <audit,todo_local_effect> model
  match find(owner.tasks, fn(item) target_id == task/id(item))
    Nothing -> owner(notice = "Task not found for local editing.")
    Just(found) -> {
      audit("Opened local edit state for task #" ++ target_id.show)
      start_task_editor(found)
      owner(notice = "Editing task locally before committing the title.")
    }

fun todo_set_task_edit_draft(owner : model, target_id : int, draft : string) : <todo_local_effect> model
  match find(owner.tasks, fn(item) target_id == task/id(item))
    Nothing -> owner(notice = "Task edit draft target was missing.")
    Just(found) -> {
      update_task_editor_draft(found, draft)
      owner
    }

fun todo_cancel_task_edit(owner : model, target_id : int) : <todo_local_effect> model
  match find(owner.tasks, fn(item) target_id == task/id(item))
    Nothing -> owner(notice = "Task cancel target was missing.")
    Just(found) -> {
      cancel_task_editor(found)
      owner(notice = "Cancelled local task edit.")
    }

fun todo_save_task_edit(owner : model, target_id : int) : <audit,todo_local_effect> model
  match find(owner.tasks, fn(item) target_id == task/id(item))
    Nothing -> owner(notice = "Task not found while saving the local edit.")
    Just(found) -> {
      val draft = task_editor_draft(found)
      if draft == "" then
        owner(notice = "Task title cannot be empty.")
      else {
        audit("Saved local task edit for #" ++ target_id.show)
        cancel_task_editor(found)
        val renamed = owner(tasks = rename_task(owner.tasks, target_id, draft))
        renamed(notice = "Saved task title from local state.")
      }
    }

fun todo_handle_toggle(owner : model, payload : string) : <audit,div> model
  audit("Toggled task state from the Koka reducer.")
  owner(tasks = toggle_tasks(payload, owner.tasks), notice = "Toggled a task.")

fun todo_handle_remove(owner : model, payload : string) : <confirm_action,audit,clear_local_state,div> model
  match find_by_remove(payload, owner.tasks)
    Nothing -> owner(notice = "Task not found for removal.")
    Just(found) ->
      if confirm_action("Remove `" ++ found.title ++ "`?") then {
        audit("Removed task after confirmation: " ++ found.title)
        clear_task_editor(found)
        val next = owner(tasks = remove_tasks(payload, owner.tasks))
        next(notice = "Task removed after confirm effect.")
      } else
        owner(notice = "Removal cancelled by confirm effect.")

fun todo_handle_clear_completed(owner : model) : <confirm_action,audit,clear_local_state,div> model
  if not(any(owner.tasks, fn(item) item.done)) then
    owner(notice = "There are no completed tasks to clear.")
  else if confirm_action("Clear every completed task?") then {
    audit("Cleared completed tasks.")
    clear_done_local_state(owner.tasks)
    val next = owner(tasks = clear_completed_tasks(owner.tasks))
    next(notice = "Completed tasks cleared after confirm effect.")
  } else
    owner(notice = "Clear completed cancelled.")

pub fun dispatch_todo_action(action : todo_action, owner : model) : <confirm_action,audit,div> model
  match action
    Add_task -> commit_task_hooks(owner, fn() todo_add_task(owner))
    Set_filter(filter_name) -> owner(filter_name = filter_name, notice = "Primary list switched to `" ++ filter_name ++ "`.")
    Clear_completed -> commit_task_hooks(owner, fn() todo_handle_clear_completed(owner))
    Toggle_task(task_id) -> todo_handle_toggle(owner, "toggle-" ++ task_id.show)
    Remove_task(task_id) -> commit_task_hooks(owner, fn() todo_handle_remove(owner, "remove-" ++ task_id.show))
    Start_task_edit(task_id) -> commit_task_hooks(owner, fn() todo_start_task_edit(owner, task_id))
    Save_task_edit(task_id) -> commit_task_hooks(owner, fn() todo_save_task_edit(owner, task_id))

fun decode_todo_action(payload : string, owner : model) : <div> maybe<todo_action>
  val tasks = owner.tasks
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
  else match task_id_from_toggle(payload, tasks)
    Just(task_id) -> Just(Toggle_task(task_id))
    Nothing -> match task_id_from_remove(payload, tasks)
      Just(task_id) -> Just(Remove_task(task_id))
      Nothing -> match task_id_from_edit(payload, tasks)
        Just(task_id) -> Just(Start_task_edit(task_id))
        Nothing -> match task_id_from_save(payload, tasks)
          Just(task_id) -> Just(Save_task_edit(task_id))
          Nothing -> Nothing

pub fun route_todo_click(payload : string, owner : model) : <confirm_action,audit,div> maybe<model>
  match decode_todo_action(payload, owner)
    Just(action) -> Just(dispatch_todo_action(action, owner))
    Nothing -> match task_id_from_cancel(payload, owner.tasks)
      Just(target_id) -> Just(commit_task_tree(owner, fn() todo_cancel_task_edit(owner, target_id)))
      Nothing -> Nothing

pub fun route_todo_input(channel : string, value : string, owner : model) : <div> maybe<model>
  if channel == "draft" then
    Just(owner(draft = value))
  else
    match find_task_draft_channel(channel, owner.tasks)
      Just(target_id) -> Just(commit_task_tree(owner, fn() todo_set_task_edit_draft(owner, target_id, value)))
      Nothing -> Nothing