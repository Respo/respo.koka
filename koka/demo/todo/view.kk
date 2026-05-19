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
  model_notice(owner) == "Added a new task from the Koka store."

pub fun task_item_view(item : task) : todo_view_effect vnode
  component(task_hook_scope(item), fn() {
    val item_scope = task_hook_scope(item)
    val (editing, set_editing) = use_state_pair(flag_state_codec, False)
    val (draft, set_draft) = use_state_pair(text_state_codec, task_title(item))
    use_effect([task_id(item).show, if editing then "editing" else "idle"], fn(root_id) {
      if editing then {
        browser_focus(root_id, task_draft_channel(item))
        browser_flash_marker(root_id, task_draft_channel(item), "effect-pulse")
      } else ()
    })
    val detail = if editing then
        node_class("div", "editor-" ++ task_id(item).show, "task-main", [
          text_input(task_draft_channel(item), "input", draft, "Edit title locally before saving...", [text_attr("data-k-effect", task_draft_channel(item))], [
            on_named_input(item_scope, "draft-input", fn(value, owner) commit_task_tree(owner, fn() {
              set_editing(True)
              set_draft(value)
              owner
            })),
            dispatch_todo_enter(Save_task_edit(task_id(item))),
          ]),
        ])
      else
        node_class("div", "meta-" ++ task_id(item).show, "task-main", [
          text_class("strong", "title-" ++ task_id(item).show, "task-title", task_title(item)),
          text_class("span", "status-" ++ task_id(item).show, "task-status", status_text(task_done(item))),
        ])
    val actions = if editing then
        [
          button_class(task_save_id(item), "button button-primary", [dispatch_todo_click(Save_task_edit(task_id(item)))], "Save"),
          button_class(task_cancel_id(item), "button", [on_named_click(item_scope, "cancel-edit", fn(owner) commit_task_tree(owner, fn() {
            clear_slot(task_editing_slot(item))
            clear_slot(task_draft_slot(item))
            set_notice(owner, "Cancelled local task edit.")
          }))], "Cancel"),
        ]
      else
        [
          button_class(task_edit_id(item), "button", [dispatch_todo_click(Start_task_edit(task_id(item)))], "Edit"),
          button_class(task_toggle_id(item), "button", [dispatch_todo_click(Toggle_task(task_id(item)))], if task_done(item) then "Undo" else "Done"),
          button_class(task_remove_id(item), "button button-danger", [dispatch_todo_click(Remove_task(task_id(item)))], "Remove"),
        ]
    node_class("li", task_id(item).show, "task-item", [
      detail,
      node_class("div", "actions-" ++ task_id(item).show, "task-actions", actions),
    ])
  })

fun render_task_items_view(tasks : list<task>) : todo_view_effect list<vnode>
  match tasks
    Nil -> Nil
    Cons(item, rest) -> Cons(task_item_view(item), render_task_items_view(rest))

fun task_list(key : string, tasks : list<task>) : todo_view_effect vnode
  match tasks
    Nil -> text_class("p", key ++ "-empty", "empty", "No tasks in this view.")
    Cons(_, _) -> node_class("ul", key, "task-list", render_task_items_view(tasks))

fun filter_button(label : string, value : string, active : bool) : <register_listener<model,browser_event_effect>,div> vnode
  val class_name = if active then "button button-active" else "button"
  button_class(value, class_name, [dispatch_todo_click(Set_filter(value))], label)

pub fun render_todo_panel(item : model) : todo_view_effect vnode
  component(todo_effect_scope(), fn() {
    val panel_scope = todo_effect_scope()
    val visible = tasks_for(model_filter_name(item), model_tasks(item))
    val total = count_all(model_tasks(item))
    use_effect([model_notice(item), model_draft(item), total.show], fn(root_id) {
      if is_recent_add(item) then browser_focus(root_id, "draft") else ()
    })
    use_effect([model_notice(item), total.show], fn(root_id) {
      if is_recent_add(item) then browser_flash_marker(root_id, "todo-note", "effect-pulse") else ()
    })
    panel("Todo", model_notice(item), "todo", "todo-panel", [
      node_class("div", "summary", "summary-row", [
        summary_chip("Tasks", count_all(model_tasks(item)).show),
        summary_chip("Done", count_done(model_tasks(item)).show),
        summary_chip("Filter", model_filter_name(item)),
      ]),
      node_class("div", "composer", "composer-row", [
        text_input("draft", "input", model_draft(item), "Add a task or effect experiment...", [text_attr("data-k-effect", "draft")], [
          on_named_input(panel_scope, "draft-input", fn(value, owner) set_draft(owner, value)),
          dispatch_todo_enter(Add_task),
        ]),
        button_class("add-task", "button button-primary", [dispatch_todo_click(Add_task)], "Add"),
        button_class("clear-completed", "button", [dispatch_todo_click(Clear_completed)], "Clear done"),
      ]),
      node_class("div", "filters", "button-row", [
        filter_button("All", "all", model_filter_name(item) == "all"),
        filter_button("Active", "active", model_filter_name(item) == "active"),
        filter_button("Done", "done", model_filter_name(item) == "done"),
      ]),
      task_list("visible-tasks", visible),
    ])
  })
