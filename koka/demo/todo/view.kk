module demo/todo/view

import demo/model
import demo/shared
import demo/todo/events
import demo/todo/state
import runtime/dom
import respo/core
import respo/state

fun status_text(done : bool) : string
  if done then "done" else "open"

fun draft_input_slot() : state_slot
  named_slot("todo/events", "draft-input")

fun filter_click_slot(value : string) : state_slot
  named_slot("todo/events/filter", value)

fun task_draft_input_listener_slot(item : task) : state_slot
  named_slot(state_slot_path(task_draft_slot(item)), "input")

fun task_cancel_listener_slot(item : task) : state_slot
  named_slot(state_slot_path(task_editing_slot(item)), "cancel")

fun todo_click_slot(payload : string) : state_slot
  named_slot("todo/events/click", payload)

fun todo_enter_slot(payload : string) : state_slot
  named_slot("todo/events/enter", payload)

fun route_todo(payload : string, owner : model) : <audit,confirm_action,current_operator,fetch_lab_snapshot,now_label,post_lab_reply,wait_ms,div> model
  match route_todo_click(payload, owner)
    Just(result) -> result
    Nothing -> owner

fun is_recent_add(owner : model) : bool
  model_notice(owner) == "Added a new task from the Koka store."

pub fun task_item_view(item : task) : <use_state,use_effect,on_click<model,browser_event_effect>,on_input<model>,on_enter<model,browser_event_effect>,div> vnode
  val editing = use_state(task_editing_slot(item), flag_state_codec, False)
  val draft = use_state(task_draft_slot(item), text_state_codec, task_title(item))
  use_effect(task_focus_effect_slot(item), [task_id(item).show, if editing then "editing" else "idle"], fn(root_id) {
    if editing then {
      browser_focus(root_id, task_draft_channel(item))
      browser_flash_marker(root_id, task_draft_channel(item), "effect-pulse")
    } else ()
  })
  val detail = if editing then
      el("div", "editor-" ++ task_id(item).show, [class_attr("task-main")], Nil, "", [
        el("input", task_draft_channel(item), [class_attr("input"), text_attr("type", "text"), text_attr("value", draft), text_attr("placeholder", "Edit title locally before saving..."), text_attr("data-k-effect", task_draft_channel(item))], [on_input(task_draft_input_listener_slot(item), fn(value, owner) commit_task_tree(owner, fn() {
          val (_editing, set_editing) = use_state_pair(task_editing_slot(item), flag_state_codec, False)
          val (_draft, set_draft) = use_state_pair(task_draft_slot(item), text_state_codec, task_title(item))
          set_editing(True)
          set_draft(value)
          owner
        })), on_enter(todo_enter_slot(task_save_id(item)), fn(owner) route_todo(task_save_id(item), owner))], "", Nil),
      ])
    else
      el("div", "meta-" ++ task_id(item).show, [class_attr("task-main")], Nil, "", [
        el("strong", "title-" ++ task_id(item).show, [class_attr("task-title")], Nil, task_title(item), Nil),
        el("span", "status-" ++ task_id(item).show, [class_attr("task-status")], Nil, status_text(task_done(item)), Nil),
      ])
  val actions = if editing then
      [
        el("button", task_save_id(item), [class_attr("button button-primary")], [on_click(todo_click_slot(task_save_id(item)), fn(owner) route_todo(task_save_id(item), owner))], "Save", Nil),
        el("button", task_cancel_id(item), [class_attr("button")], [on_click(task_cancel_listener_slot(item), fn(owner) commit_task_tree(owner, fn() {
          clear_slot(task_editing_slot(item))
          clear_slot(task_draft_slot(item))
          set_notice(owner, "Cancelled local task edit.")
        }))], "Cancel", Nil),
      ]
    else
      [
        el("button", task_edit_id(item), [class_attr("button")], [on_click(todo_click_slot(task_edit_id(item)), fn(owner) route_todo(task_edit_id(item), owner))], "Edit", Nil),
        el("button", task_toggle_id(item), [class_attr("button")], [on_click(todo_click_slot(task_toggle_id(item)), fn(owner) route_todo(task_toggle_id(item), owner))], if task_done(item) then "Undo" else "Done", Nil),
        el("button", task_remove_id(item), [class_attr("button button-danger")], [on_click(todo_click_slot(task_remove_id(item)), fn(owner) route_todo(task_remove_id(item), owner))], "Remove", Nil),
      ]
  el("li", task_id(item).show, [class_attr("task-item")], Nil, "", [
    detail,
    el("div", "actions-" ++ task_id(item).show, [class_attr("task-actions")], Nil, "", actions),
  ])

fun render_task_items_view(tasks : list<task>) : <use_state,use_effect,on_click<model,browser_event_effect>,on_input<model>,on_enter<model,browser_event_effect>,div> list<vnode>
  match tasks
    Nil -> Nil
    Cons(item, rest) -> Cons(task_item_view(item), render_task_items_view(rest))

fun task_list(key : string, tasks : list<task>) : <use_state,use_effect,on_click<model,browser_event_effect>,on_input<model>,on_enter<model,browser_event_effect>,div> vnode
  match tasks
    Nil -> el("p", key ++ "-empty", [class_attr("empty")], Nil, "No tasks in this view.", Nil)
    Cons(_, _) -> el("ul", key, [class_attr("task-list")], Nil, "", render_task_items_view(tasks))

fun filter_button(label : string, value : string, active : bool) : <on_click<model,browser_event_effect>,div> vnode
  val class_name = if active then "button button-active" else "button"
  el("button", value, [class_attr(class_name)], [on_click(filter_click_slot(value), fn(owner) set_filter(owner, value))], label, Nil)

pub fun render_todo_panel(item : model) : <use_state,use_effect,on_click<model,browser_event_effect>,on_input<model>,on_enter<model,browser_event_effect>,div> vnode
  val visible = tasks_for(model_filter_name(item), model_tasks(item))
  val total = count_all(model_tasks(item))
  use_effect(todo_draft_focus_slot(), [model_notice(item), model_draft(item), total.show], fn(root_id) {
    if is_recent_add(item) then browser_focus(root_id, "draft") else ()
  })
  use_effect(todo_notice_pulse_slot(), [model_notice(item), total.show], fn(root_id) {
    if is_recent_add(item) then browser_flash_marker(root_id, "todo-note", "effect-pulse") else ()
  })
  panel("Todo", model_notice(item), "todo", "todo-panel", [
    el("div", "summary", [class_attr("summary-row")], Nil, "", [
      summary_chip("Tasks", count_all(model_tasks(item)).show),
      summary_chip("Done", count_done(model_tasks(item)).show),
      summary_chip("Filter", model_filter_name(item)),
    ]),
    el("div", "composer", [class_attr("composer-row")], Nil, "", [
      el("input", "draft", [class_attr("input"), text_attr("type", "text"), text_attr("value", model_draft(item)), text_attr("placeholder", "Add a task or effect experiment...")], [on_input(draft_input_slot(), fn(value, owner) set_draft(owner, value)), on_enter(todo_enter_slot("add-task"), fn(owner) route_todo("add-task", owner))], "", Nil),
      el("button", "add-task", [class_attr("button button-primary")], [on_click(todo_click_slot("add-task"), fn(owner) route_todo("add-task", owner))], "Add", Nil),
      el("button", "clear-completed", [class_attr("button")], [on_click(todo_click_slot("clear-completed"), fn(owner) route_todo("clear-completed", owner))], "Clear done", Nil),
    ]),
    el("div", "filters", [class_attr("button-row")], Nil, "", [
      filter_button("All", "all", model_filter_name(item) == "all"),
      filter_button("Active", "active", model_filter_name(item) == "active"),
      filter_button("Done", "done", model_filter_name(item) == "done"),
    ]),
    task_list("visible-tasks", visible),
  ])