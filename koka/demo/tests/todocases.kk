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
  val (started, _focus_target) = match handle_todo_click("edit-2", initial_model())
    Just(result) -> result
    Nothing -> (initial_model(), Nothing)
  val drafted = match handle_todo_input("task-draft-2", "Prototype local title edits before save", started)
    Just(result) -> result
    Nothing -> started
  val saved = match handle_todo_click("save-2", drafted)
    Just(result) -> fst(result)
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
  val (started, _focus_target) = match handle_todo_click("edit-2", initial_model())
    Just(result) -> result
    Nothing -> (initial_model(), Nothing)
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
  val (next, target) = match handle_todo_click("add-task", seeded)
    Just(result) -> result
    Nothing -> (seeded, Nothing)
  val focused_draft = match target
    Just(field_name) -> field_name == "draft"
    Nothing -> False
  bool_result("Add task schedules focus", "draft=" ++ model_draft(next) ++ ", target=" ++ maybe_text(target), model_draft(next) == "" && focused_draft)

pub fun start_edit_focus_test() : <div> test_result
  with fun confirm_action(_message) False
  with fun audit(_message) ()
  val (next, target) = match handle_todo_click("edit-2", initial_model())
    Just(result) -> result
    Nothing -> (initial_model(), Nothing)
  val expected = match find_task_by_id(2, model_tasks(next))
    Just(item) -> task_draft_channel(item)
    Nothing -> "missing"
  val local = match find_task_by_id(2, model_tasks(next))
    Just(item) -> task_editor_snapshot(next, item)
    Nothing -> Task_editor_state(False, "")
  val focused_editor = match target
    Just(field_name) -> field_name == expected
    Nothing -> False
  bool_result("Start edit schedules focus", "expected=" ++ expected ++ ", target=" ++ maybe_text(target), task_editor_editing(local) && focused_editor)