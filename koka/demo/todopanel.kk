module demo/todopanel

import demo/model
import demo/shared
import respo/core

fun status_text(done : bool) : string
  if done then "done" else "open"

fun task_item(owner : model, item : task) : <div> vnode
  val editing = task_is_editing(owner, task_id(item))
  val draft = task_edit_draft(owner, task_id(item), task_title(item))
  val detail = if editing then
      el("div", "editor-" ++ task_id(item).show, [class_attr("task-main")], Nil, "", [
        el("input", task_draft_channel(item), [class_attr("input"), text_attr("type", "text"), text_attr("value", draft), text_attr("placeholder", "Edit title locally before saving...")], [input_listener(task_draft_channel(item)), enter_listener(task_save_id(item))], "", Nil),
      ])
    else
      el("div", "meta-" ++ task_id(item).show, [class_attr("task-main")], Nil, "", [
        el("strong", "title-" ++ task_id(item).show, [class_attr("task-title")], Nil, task_title(item), Nil),
        el("span", "status-" ++ task_id(item).show, [class_attr("task-status")], Nil, status_text(task_done(item)), Nil),
      ])
  val actions = if editing then
      [
        el("button", task_save_id(item), [class_attr("button button-primary")], [click_listener(task_save_id(item))], "Save", Nil),
        el("button", task_cancel_id(item), [class_attr("button")], [click_listener(task_cancel_id(item))], "Cancel", Nil),
      ]
    else
      [
        el("button", task_edit_id(item), [class_attr("button")], [click_listener(task_edit_id(item))], "Edit", Nil),
        el("button", task_toggle_id(item), [class_attr("button")], [click_listener(task_toggle_id(item))], if task_done(item) then "Undo" else "Done", Nil),
        el("button", task_remove_id(item), [class_attr("button button-danger")], [click_listener(task_remove_id(item))], "Remove", Nil),
      ]
  el("li", task_id(item).show, [class_attr("task-item")], Nil, "", [
    detail,
    el("div", "actions-" ++ task_id(item).show, [class_attr("task-actions")], Nil, "", actions),
  ])

fun render_task_items(owner : model, tasks : list<task>) : <div> list<vnode>
  match tasks
    Nil -> Nil
    Cons(item, rest) -> Cons(task_item(owner, item), render_task_items(owner, rest))

fun task_list(owner : model, key : string, tasks : list<task>) : <div> vnode
  match tasks
    Nil -> el("p", key ++ "-empty", [class_attr("empty")], Nil, "No tasks in this view.", Nil)
    Cons(_, _) -> el("ul", key, [class_attr("task-list")], Nil, "", render_task_items(owner, tasks))

fun filter_button(label : string, value : string, active : bool) : vnode
  val class_name = if active then "button button-active" else "button"
  el("button", value, [class_attr(class_name)], [click_listener("set-filter-" ++ value)], label, Nil)

pub fun todo_panel(item : model) : <div> vnode
  val visible = tasks_for(model_filter_name(item), model_tasks(item))
  panel("Todo", model_notice(item), "todo", "todo-panel", [
    el("div", "summary", [class_attr("summary-row")], Nil, "", [
      summary_chip("Tasks", count_all(model_tasks(item)).show),
      summary_chip("Done", count_done(model_tasks(item)).show),
      summary_chip("Filter", model_filter_name(item)),
    ]),
    el("div", "composer", [class_attr("composer-row")], Nil, "", [
      el("input", "draft", [class_attr("input"), text_attr("type", "text"), text_attr("value", model_draft(item)), text_attr("placeholder", "Add a task or effect experiment...")], [input_listener("draft"), enter_listener("add-task")], "", Nil),
      el("button", "add-task", [class_attr("button button-primary")], [click_listener("add-task")], "Add", Nil),
      el("button", "clear-completed", [class_attr("button")], [click_listener("clear-completed")], "Clear done", Nil),
    ]),
    el("div", "filters", [class_attr("button-row")], Nil, "", [
      filter_button("All", "all", model_filter_name(item) == "all"),
      filter_button("Active", "active", model_filter_name(item) == "active"),
      filter_button("Done", "done", model_filter_name(item) == "done"),
    ]),
    task_list(item, "visible-tasks", visible),
  ])
