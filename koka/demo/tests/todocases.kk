module demo/tests/todocases

import demo/model
import demo/seed
import demo/tests/support
import demo/todo/state
import demo/todopanel
import respo/core
import respo/renderer
import respo/state

pub fun todo_edit_local_state_test() : <div> test_result
  with fun confirm_action(_message) False
  with fun audit(_message) ()
  val started = match handle_todo_click("edit-2", initial_model())
    Just(result) -> result
    Nothing -> initial_model()
  val drafted = match handle_todo_input("task-draft-2", "Prototype local title edits before save", started)
    Just(result) -> result
    Nothing -> started
  val saved = match handle_todo_click("save-2", drafted)
    Just(result) -> result
    Nothing -> drafted
  val title = match find(saved.tasks, fn(item) 2 == task/id(item))
    Just(item) -> item.title
    Nothing -> "missing"
  val started_task = match find(started.tasks, fn(item) 2 == task/id(item))
    Just(item) -> snapshot_task_editor(started, item)
    Nothing -> Task_editor_state(False, "")
  val saved_task = match find(saved.tasks, fn(item) 2 == task/id(item))
    Just(item) -> snapshot_task_editor(saved, item)
    Nothing -> Task_editor_state(False, "")
  val local_entries = count_entries(saved.todo_local_tree)
  Test_result(
    "Todo item local editing",
    "title=" ++ title ++ ", local=" ++ local_entries.show ++ ", editing=" ++ task_editor_state/editing(started_task).show,
    title == "Prototype local title edits before save" && local_entries == 0 && not(task_editor_state/editing(saved_task)))

pub fun todo_edit_diff_test() : <div> test_result
  with fun confirm_action(_message) False
  with fun audit(_message) ()
  val started = match handle_todo_click("edit-2", initial_model())
    Just(result) -> result
    Nothing -> initial_model()
  val drafted = match handle_todo_input("task-draft-2", "x", started)
    Just(result) -> result
    Nothing -> started
  val patches = diff_node("0", todo_panel(started), todo_panel(drafted))
  val attr_patches = length(filter(patches, fn(item) patch/kind(item) == "set-attr"))
  val replace_patches = length(filter(patches, fn(item) patch/kind(item) == "replace"))
  Test_result(
    "Todo draft uses attribute patch",
    "patches=" ++ length(patches).show ++ ", attrs=" ++ attr_patches.show ++ ", replace=" ++ replace_patches.show,
    attr_patches == 1 && replace_patches == 0)

pub fun add_task_focus_test() : <div> test_result
  with fun confirm_action(_message) False
  with fun audit(_message) ()
  val seeded = initial_model()(draft = "Queue a fresh task")
  val next = match handle_todo_click("add-task", seeded)
    Just(result) -> result
    Nothing -> seeded
  val (rendered, panel_node, effects, _handlers) = run_todo_panel(next)
  val focused_draft = any(effects, fn(item) scheduled_effect/path(item) == state_slot/path(todo_draft_focus_slot()))
  val pulsed_notice = any(effects, fn(item) scheduled_effect/path(item) == state_slot/path(todo_notice_pulse_slot()))
  val has_focus_marker = vnode_has_attr_value(panel_node, "data-k-effect", "draft")
  Test_result(
    "Add task schedules focus",
    "draft=" ++ rendered.draft ++ ", effects=" ++ length(effects).show,
    rendered.draft == "" && focused_draft && pulsed_notice && has_focus_marker)

pub fun start_edit_focus_test() : <div> test_result
  with fun confirm_action(_message) False
  with fun audit(_message) ()
  val next = match handle_todo_click("edit-2", initial_model())
    Just(result) -> result
    Nothing -> initial_model()
  val (rendered, panel_node, effects, _handlers) = run_todo_panel(next)
  val expected = match find(rendered.tasks, fn(item) 2 == task/id(item))
    Just(item) -> state_slot/path(task_focus_effect_slot(item))
    Nothing -> "missing"
  val expected_marker = match find(rendered.tasks, fn(item) 2 == task/id(item))
    Just(item) -> "task-draft-" ++ task/id(item).show
    Nothing -> "missing"
  val local = match find(rendered.tasks, fn(item) 2 == task/id(item))
    Just(item) -> snapshot_task_editor(next, item)
    Nothing -> Task_editor_state(False, "")
  val focused_editor = any(effects, fn(item) scheduled_effect/path(item) == expected)
  val has_focus_marker = vnode_has_attr_value(panel_node, "data-k-effect", expected_marker)
  Test_result("Start edit schedules focus", "expected=" ++ expected ++ ", effects=" ++ length(effects).show, task_editor_state/editing(local) && focused_editor && has_focus_marker)