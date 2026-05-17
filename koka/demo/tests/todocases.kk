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
  val title = match find_task_by_id(2, model_tasks(saved))
    Just(item) -> task_title(item)
    Nothing -> "missing"
  val started_task = match find_task_by_id(2, model_tasks(started))
    Just(item) -> task_editor_snapshot(started, item)
    Nothing -> Task_editor_state(False, "")
  val saved_task = match find_task_by_id(2, model_tasks(saved))
    Just(item) -> task_editor_snapshot(saved, item)
    Nothing -> Task_editor_state(False, "")
  val local_entries = count_entries(model_todo_local_tree(saved))
  bool_result(
    "Todo item local editing",
    "title=" ++ title ++ ", local=" ++ local_entries.show ++ ", editing=" ++ task_editor_editing(started_task).show,
    title == "Prototype local title edits before save" && local_entries == 0 && not(task_editor_editing(saved_task)))

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
  bool_result(
    "Todo draft uses attribute patch",
    "patches=" ++ count_patches(patches).show ++ ", attrs=" ++ count_patch_kind(patches, "set-attr").show ++ ", replace=" ++ count_patch_kind(patches, "replace").show,
    count_patch_kind(patches, "set-attr") == 1 && count_patch_kind(patches, "replace") == 0)

pub fun add_task_focus_test() : <div> test_result
  with fun confirm_action(_message) False
  with fun audit(_message) ()
  val seeded = set_draft(initial_model(), "Queue a fresh task")
  val next = match handle_todo_click("add-task", seeded)
    Just(result) -> result
    Nothing -> seeded
  val (rendered, _panel_node, effects, _handlers) = run_todo_panel(next)
  val focused_draft = has_effect(state_slot_path(todo_draft_focus_slot()), effects)
  val pulsed_notice = has_effect(state_slot_path(todo_notice_pulse_slot()), effects)
  bool_result(
    "Add task schedules focus",
    "draft=" ++ model_draft(rendered) ++ ", effects=" ++ count_effects(effects).show,
    model_draft(rendered) == "" && focused_draft && pulsed_notice)

pub fun start_edit_focus_test() : <div> test_result
  with fun confirm_action(_message) False
  with fun audit(_message) ()
  val next = match handle_todo_click("edit-2", initial_model())
    Just(result) -> result
    Nothing -> initial_model()
  val (rendered, _panel_node, effects, _handlers) = run_todo_panel(next)
  val expected = match find_task_by_id(2, model_tasks(rendered))
    Just(item) -> state_slot_path(task_focus_effect_slot(item))
    Nothing -> "missing"
  val local = match find_task_by_id(2, model_tasks(rendered))
    Just(item) -> task_editor_snapshot(next, item)
    Nothing -> Task_editor_state(False, "")
  val focused_editor = has_effect(expected, effects)
  bool_result("Start edit schedules focus", "expected=" ++ expected ++ ", effects=" ++ count_effects(effects).show, task_editor_editing(local) && focused_editor)