module demo/todo/events

import demo/model
import demo/todo/state
import library/maybe
import respo/core
import respo/state

pub type todo_action
  Add_task
  Set_filter(filter_name : string)
  Clear_completed

pub fun todo_action_payload(action : todo_action) : string
  match action
    Add_task -> "add-task"
    Set_filter(filter_name) -> "set-filter-" ++ filter_name
    Clear_completed -> "clear-completed"

pub fun dispatch_todo_click(action : todo_action) : listener
  click_listener(todo_action_payload(action))

pub fun dispatch_todo_enter(action : todo_action) : listener
  enter_listener(todo_action_payload(action))

fun append_tasks(tasks : list<task>, item : task) : <div> list<task>
  tasks ++ [item]

fun clear_completed_tasks(tasks : list<task>) : <div> list<task>
  filter(tasks, fn(item) not(item.done))

fun clear_done_local_state(tasks : list<task>) : <clear_local_state,div> ()
  clear_done_task_editors(tasks)

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
  else
    Nothing

pub fun route_todo_click(payload : string, owner : model) : <confirm_action,audit,div> maybe<model>
  decode_todo_action(payload, owner).map(fn(action) dispatch_todo_action(action, owner))

pub fun route_todo_input(channel : string, value : string, owner : model) : <div> maybe<model>
  if channel == "draft" then
    Just(owner(draft = value))
  else
    Nothing