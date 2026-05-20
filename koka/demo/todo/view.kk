module demo/todo/view

import demo/model
import demo/shared
import demo/todo/events
import demo/todo/state
import runtime/dom
import respo/core
import respo/state

alias todo_view_effect = <push_hook_scope,pop_hook_scope,use_state_pair,use_effect,register_listener<model,browser_event_effect>,div>

fun status_text(done : bool) : string
  if done then "done" else "open"

fun is_recent_add(owner : model) : bool
  owner.notice == "Added a new task from the Koka store."

pub fun task_item_view(item : task) : todo_view_effect vnode
  component(task_hook_scope(item), fn() {
    val item_scope = task_hook_scope(item)
    val tid = task/id(item)
    val (editing, set_editing) = use_state_pair(flag_state_codec, False)
    val (draft, set_draft) = use_state_pair(text_state_codec, item.title)
    use_effect([tid.show, if editing then "editing" else "idle"], fn(root_id) {
      if editing then {
        browser_focus(root_id, "task-draft-" ++ tid.show)
        browser_flash_marker(root_id, "task-draft-" ++ tid.show, "effect-pulse")
      } else ()
    })
    val detail = if editing then
        node_class("div", "editor-" ++ tid.show, "task-main", [
          text_input("task-draft-" ++ tid.show, "input", draft, "Edit title locally before saving...", [text_attr("data-k-effect", "task-draft-" ++ tid.show)], [
            on_named_input(item_scope, "draft-input", fn(value, owner) commit_task_tree(owner, fn() {
              set_editing(True)
              set_draft(value)
              owner
            })),
            dispatch_todo_enter(Save_task_edit(tid)),
          ]),
        ])
      else
        node_class("div", "meta-" ++ tid.show, "task-main", [
          text_class("strong", "title-" ++ tid.show, "task-title", item.title),
          text_class("span", "status-" ++ tid.show, "task-status", status_text(item.done)),
        ])
    val actions = if editing then
        [
          button_class("save-" ++ tid.show, "button button-primary", [dispatch_todo_click(Save_task_edit(tid))], "Save"),
          button_class("cancel-" ++ tid.show, "button", [on_named_click(item_scope, "cancel-edit", fn(owner) commit_task_tree(owner, fn() {
            clear_slot(task_editing_slot(item))
            clear_slot(task_draft_slot(item))
            owner(notice = "Cancelled local task edit.")
          }))], "Cancel"),
        ]
      else
        [
          button_class("edit-" ++ tid.show, "button", [dispatch_todo_click(Start_task_edit(tid))], "Edit"),
          button_class("toggle-" ++ tid.show, "button", [dispatch_todo_click(Toggle_task(tid))], if item.done then "Undo" else "Done"),
          button_class("remove-" ++ tid.show, "button button-danger", [dispatch_todo_click(Remove_task(tid))], "Remove"),
        ]
    node_class("li", tid.show, "task-item", [
      detail,
      node_class("div", "actions-" ++ tid.show, "task-actions", actions),
    ])
  })

fun render_task_items_view(tasks : list<task>) : todo_view_effect list<vnode>
  map(tasks, task_item_view)

fun task_list(key : string, tasks : list<task>) : todo_view_effect vnode
  if is-empty(tasks) then text_class("p", key ++ "-empty", "empty", "No tasks in this view.") else node_class("ul", key, "task-list", render_task_items_view(tasks))

fun filter_button(label : string, value : string, active : bool) : <register_listener<model,browser_event_effect>,div> vnode
  val class_name = if active then "button button-active" else "button"
  button_class(value, class_name, [dispatch_todo_click(Set_filter(value))], label)

pub fun render_todo_panel(item : model) : todo_view_effect vnode
  component(todo_effect_scope(), fn() {
    val panel_scope = todo_effect_scope()
    val visible = tasks_for(item.filter_name, item.tasks)
    val total = length(item.tasks)
    use_effect([item.notice, item.draft, total.show], fn(root_id) {
      if is_recent_add(item) then browser_focus(root_id, "draft") else ()
    })
    use_effect([item.notice, total.show], fn(root_id) {
      if is_recent_add(item) then browser_flash_marker(root_id, "todo-note", "effect-pulse") else ()
    })
    panel("Todo", item.notice, "todo", "todo-panel", [
      node_class("div", "summary", "summary-row", [
        summary_chip("Tasks", length(item.tasks).show),
        summary_chip("Done", length(filter(item.tasks, fn(task_item) task_item.done)).show),
        summary_chip("Filter", item.filter_name),
      ]),
      node_class("div", "composer", "composer-row", [
        text_input("draft", "input", item.draft, "Add a task or effect experiment...", [text_attr("data-k-effect", "draft")], [
          on_named_input(panel_scope, "draft-input", fn(value, owner : model) owner(draft = value)),
          dispatch_todo_enter(Add_task),
        ]),
        button_class("add-task", "button button-primary", [dispatch_todo_click(Add_task)], "Add"),
        button_class("clear-completed", "button", [dispatch_todo_click(Clear_completed)], "Clear done"),
      ]),
      node_class("div", "filters", "button-row", [
        filter_button("All", "all", item.filter_name == "all"),
        filter_button("Active", "active", item.filter_name == "active"),
        filter_button("Done", "done", item.filter_name == "done"),
      ]),
      task_list("visible-tasks", visible),
    ])
  })
