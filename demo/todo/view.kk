module demo/todo/view

import demo/model
import demo/shared
import demo/todo/events
import demo/todo/state
import demo/todo/viewmodel
import runtime/dom
import explore/react/core
import explore/react/state

alias todo_view_effect = <current_hook_scope_name,push_hook_scope,pop_hook_scope,todo_local_effect,register_listener<model,browser_event_effect>>

fun status_text(done : bool) : string
  if done then "done" else "open"

pub fun task_item_view(item : task) : todo_view_effect vnode
  {
    val tid = task/id(item)
    val (editing, set_editing) = use_state_pair(flag_state_codec, False)
    val (draft, set_draft) = use_state_pair(text_state_codec, item.title)
    val start_edit = on_local_click("start-edit", fn(owner : model) commit_task_tree(owner, fn() {
      audit("Opened local edit state for task #" ++ tid.show)
      set_editing(True)
      set_draft(item.title)
      owner(notice = "Editing task locally before committing the title.")
    }))
    val save_edit = on_local_click("save-edit", fn(owner : model) commit_task_tree(owner, fn() {
      if draft == "" then
        owner(notice = "Task title cannot be empty.")
      else {
        audit("Saved local task edit for #" ++ tid.show)
        set_editing(False)
        clear_task_editor(item)
        owner(
          tasks = map(owner.tasks, fn(task_item) if task/id(task_item) == tid then task_item(title = draft) else task_item),
          notice = "Saved task title from local state.")
      }
    }))
    val cancel_edit = on_local_click("cancel-edit", fn(owner : model) commit_task_tree(owner, fn() {
      set_editing(False)
      set_draft(item.title)
      clear_task_editor(item)
      owner(notice = "Cancelled local task edit.")
    }))
    val toggle_task = on_local_click("toggle-task", fn(owner : model) {
      audit("Toggled task state from the Koka reducer.")
      owner(
        tasks = map(owner.tasks, fn(task_item) if task/id(task_item) == tid then task_item(done = not(task_item.done)) else task_item),
        notice = "Toggled a task.")
    })
    val remove_task = on_local_click("remove-task", fn(owner : model) {
      if confirm_action("Remove `" ++ item.title ++ "`?") then
        commit_task_tree(owner, fn() {
          audit("Removed task after confirmation: " ++ item.title)
          clear_task_editor(item)
          owner(
            tasks = filter(owner.tasks, fn(task_item) task/id(task_item) != tid),
            notice = "Task removed after confirm effect.")
        })
      else
        owner(notice = "Removal cancelled by confirm effect.")
    })
    val save_edit_enter = on_local_enter("save-edit", fn(owner : model) commit_task_tree(owner, fn() {
      if draft == "" then
        owner(notice = "Task title cannot be empty.")
      else {
        audit("Saved local task edit for #" ++ tid.show)
        set_editing(False)
        clear_task_editor(item)
        owner(
          tasks = map(owner.tasks, fn(task_item) if task/id(task_item) == tid then task_item(title = draft) else task_item),
          notice = "Saved task title from local state.")
      }
    }))
    use_effect([tid.show, if editing then "editing" else "idle"], fn() {
      if editing then {
        dom_focus("task-draft-" ++ tid.show)
        dom_flash("task-draft-" ++ tid.show, "effect-pulse")
      } else ()
    })
    val detail = if editing then
        div([class_attr("task-main")], [
          input_text_key("task-draft-" ++ tid.show, [class_attr("input"), text_attr("data-k-effect", "task-draft-" ++ tid.show)], [
            on_local_input("draft-input", fn(value, owner) commit_task_tree(owner, fn() {
              set_editing(True)
              set_draft(value)
              owner
            })),
            save_edit_enter,
          ], draft, "Edit title locally before saving..."),
        ])
      else
        div([class_attr("task-main")], [
          strong([class_attr("task-title")], item.title),
          span([class_attr("task-status")], status_text(item.done)),
        ])
    val actions = if editing then
        [
          button([class_attr("button button-primary")], [save_edit], "Save"),
          button([class_attr("button")], [cancel_edit], "Cancel"),
        ]
      else
        [
          button([class_attr("button")], [start_edit], "Edit"),
          button([class_attr("button")], [toggle_task], if item.done then "Undo" else "Done"),
          button([class_attr("button button-danger")], [remove_task], "Remove"),
        ]
    li_key(tid.show, [class_attr("task-item")], [
      detail,
      div([class_attr("task-actions")], actions),
    ])
  }

fun render_task_items_view(tasks : list<task>) : todo_view_effect list<vnode>
  map(tasks, fn(item) component_in("tasks", task/id(item).show, fn() task_item_view(item)))

fun task_list(key : string, tasks : list<task>) : todo_view_effect vnode
  if is-empty(tasks) then p([class_attr("empty")], "No tasks in this view.") else ul_key(key, [class_attr("task-list")], render_task_items_view(tasks))

fun filter_button(label : string, value : string, active : bool) : <current_hook_scope_name,register_listener<model,browser_event_effect>,div> vnode
  val class_name = if active then "button button-active" else "button"
  button([class_attr(class_name)], [on_local_click("set-filter-" ++ value, fn(m : model) dispatch_todo_action(Set_filter(value), m))], label)

pub fun render_todo_panel(owner : model, panel_state : todo_panel_state) : todo_view_effect vnode
  {
    val visible = visible_panel_tasks(panel_state)
    val total = total_task_count(panel_state)
    val should_focus_draft = has_recent_add_notice(panel_state)
    use_effect([panel_state.notice, panel_state.draft, total.show], fn() {
      if should_focus_draft then dom_focus("draft") else ()
    })
    use_effect([panel_state.notice, total.show], fn() {
      if should_focus_draft then dom_flash("todo-note", "effect-pulse") else ()
    })
    panel("Todo", panel_state.notice, "todo", "todo-panel", [
      div([class_attr("summary-row")], [
        summary_chip("Tasks", total.show),
        summary_chip("Done", done_task_count(panel_state).show),
        summary_chip("Filter", panel_state.filter_name),
      ]),
      div([class_attr("composer-row")], [
        input_text([class_attr("input"), text_attr("data-k-effect", "draft")], [
          on_local_input("draft-input", fn(value, next_owner : model) next_owner(draft = value)),
          on_local_enter("add-task", fn(m : model) dispatch_todo_action(Add_task, m)),
        ], panel_state.draft, "Add a task or effect experiment..."),
        button([class_attr("button button-primary")], [on_local_click("add-task", fn(m : model) dispatch_todo_action(Add_task, m))], "Add"),
        button([class_attr("button")], [on_local_click("clear-completed", fn(m : model) dispatch_todo_action(Clear_completed, m))], "Clear done"),
      ]),
      div([class_attr("button-row")], [
        filter_button("All", "all", panel_state.filter_name == "all"),
        filter_button("Active", "active", panel_state.filter_name == "active"),
        filter_button("Done", "done", panel_state.filter_name == "done"),
      ]),
      task_list("visible-tasks", visible),
    ])
  }
