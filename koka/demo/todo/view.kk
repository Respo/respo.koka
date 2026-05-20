module demo/todo/view

import demo/model
import demo/shared
import demo/todo/events
import demo/todo/state
import demo/todo/viewmodel
import runtime/dom
import respo/core
import respo/state

alias todo_view_effect = <push_hook_scope,pop_hook_scope,use_state_pair,use_effect,register_listener<model,browser_event_effect>,div>

fun status_text(done : bool) : string
  if done then "done" else "open"

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
        div([class_attr("task-main")], [
          input_text_key("task-draft-" ++ tid.show, [class_attr("input"), text_attr("data-k-effect", "task-draft-" ++ tid.show)], [
            on_named_input(item_scope, "draft-input", fn(value, owner) commit_task_tree(owner, fn() {
              set_editing(True)
              set_draft(value)
              owner
            })),
            dispatch_todo_enter(Save_task_edit(tid)),
          ], draft, "Edit title locally before saving..."),
        ])
      else
        div([class_attr("task-main")], [
          strong([class_attr("task-title")], item.title),
          span([class_attr("task-status")], status_text(item.done)),
        ])
    val actions = if editing then
        [
          button([class_attr("button button-primary")], [dispatch_todo_click(Save_task_edit(tid))], "Save"),
          button([class_attr("button")], [on_named_click(item_scope, "cancel-edit", fn(owner) commit_task_tree(owner, fn() {
            clear_slot(task_editing_slot(item))
            clear_slot(task_draft_slot(item))
            owner(notice = "Cancelled local task edit.")
          }))], "Cancel"),
        ]
      else
        [
          button([class_attr("button")], [dispatch_todo_click(Start_task_edit(tid))], "Edit"),
          button([class_attr("button")], [dispatch_todo_click(Toggle_task(tid))], if item.done then "Undo" else "Done"),
          button([class_attr("button button-danger")], [dispatch_todo_click(Remove_task(tid))], "Remove"),
        ]
    li_key(tid.show, [class_attr("task-item")], [
      detail,
      div([class_attr("task-actions")], actions),
    ])
  })

fun render_task_items_view(tasks : list<task>) : todo_view_effect list<vnode>
  map(tasks, task_item_view)

fun task_list(key : string, tasks : list<task>) : todo_view_effect vnode
  if is-empty(tasks) then p([class_attr("empty")], "No tasks in this view.") else ul_key(key, [class_attr("task-list")], render_task_items_view(tasks))

fun filter_button(label : string, value : string, active : bool) : <register_listener<model,browser_event_effect>,div> vnode
  val class_name = if active then "button button-active" else "button"
  button([class_attr(class_name)], [dispatch_todo_click(Set_filter(value))], label)

pub fun render_todo_panel(owner : model, panel_state : todo_panel_state) : todo_view_effect vnode
  component(todo_effect_scope(), fn() {
    val panel_scope = todo_effect_scope()
    val visible = visible_panel_tasks(panel_state)
    val total = total_task_count(panel_state)
    use_effect([panel_state.notice, panel_state.draft, total.show], fn(root_id) {
      if has_recent_add_notice(panel_state) then browser_focus(root_id, "draft") else ()
    })
    use_effect([panel_state.notice, total.show], fn(root_id) {
      if has_recent_add_notice(panel_state) then browser_flash_marker(root_id, "todo-note", "effect-pulse") else ()
    })
    panel("Todo", panel_state.notice, "todo", "todo-panel", [
      div([class_attr("summary-row")], [
        summary_chip("Tasks", total.show),
        summary_chip("Done", done_task_count(panel_state).show),
        summary_chip("Filter", panel_state.filter_name),
      ]),
      div([class_attr("composer-row")], [
        input_text([class_attr("input"), text_attr("data-k-effect", "draft")], [
          on_named_input(panel_scope, "draft-input", fn(value, next_owner : model) next_owner(draft = value)),
          dispatch_todo_enter(Add_task),
        ], panel_state.draft, "Add a task or effect experiment..."),
        button([class_attr("button button-primary")], [dispatch_todo_click(Add_task)], "Add"),
        button([class_attr("button")], [dispatch_todo_click(Clear_completed)], "Clear done"),
      ]),
      div([class_attr("button-row")], [
        filter_button("All", "all", panel_state.filter_name == "all"),
        filter_button("Active", "active", panel_state.filter_name == "active"),
        filter_button("Done", "done", panel_state.filter_name == "done"),
      ]),
      task_list("visible-tasks", visible),
    ])
  })
