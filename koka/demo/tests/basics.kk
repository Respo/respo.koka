module demo/tests/basics

import demo/model
import demo/seed
import demo/tests/support
import demo/todo/state
import demo/todopanel
import respo/core
import respo/renderer
import respo/state

fun timer_logic() : <wait_ms> string
  wait_ms(20)
  wait_ms(20)
  wait_ms(40)
  "timer-ready"

pub fun component_render_test() : <div> test_result
  val html = render_node("0", text_node("button", "sample", props([class_attr("demo-button")], [click_listener("run-sample")]), "Run"))
  val expected = "<button data-kpath=\"0\" class=\"demo-button\" data-k-click=\"run-sample\">Run</button>"
  bool_result("Component render snapshot", if html == expected then "Stable HTML output for a small component." else html, html == expected)

pub fun confirm_decline_test() : <div> test_result
  with fun confirm_action(_message) False
  with fun audit(_message) ()
  val next = match handle_todo_click("remove-1", initial_model())
    Just(result) -> result
    Nothing -> initial_model()
  bool_result("Confirm decline keeps state", model_notice(next), count_all(model_tasks(next)) == 3)

pub fun confirm_accept_test() : <div> test_result
  with fun confirm_action(_message) True
  with fun audit(_message) ()
  val next = match handle_todo_click("remove-1", initial_model())
    Just(result) -> result
    Nothing -> initial_model()
  bool_result("Confirm accept removes task", "Remaining tasks: " ++ count_all(model_tasks(next)).show, count_all(model_tasks(next)) == 2)

pub fun ambient_filter_test() : <div> test_result
  val base = model_tasks(initial_model())
  val active_count = count_all(tasks_for("active", base))
  val done_count = count_all(tasks_for("done", base))
  bool_result("Ambient filter previews", "active=" ++ active_count.show ++ ", done=" ++ done_count.show, active_count == 2 && done_count == 1)

pub fun registered_input_handler_test() : <div> test_result
  val target_id = state_slot_path(named_listener_slot(todo_effect_scope(), Input_event, "draft-input"))
  val (next_item, _panel_node, _effects, handlers) = run_todo_panel(initial_model())
  match find_registered_input(handlers, target_id)
    Just(found_input) -> {
      val updated = run_registered_input(found_input, "closure draft", next_item)
      bool_result("Registered input handler updates draft", "inputs=" ++ count_registered_inputs(handlers).show ++ ", draft=" ++ model_draft(updated), model_draft(updated) == "closure draft")
    }
    Nothing -> bool_result("Registered input handler updates draft", target_id ++ " missing", False)

pub fun registered_click_handler_test() : <div> test_result
  with fun confirm_action(_message) False
  with fun audit(_message) ()
  with val current_operator = "test-operator"
  with fun fetch_lab_snapshot() Lab_snapshot(Nil, "empty")
  with fun now_label() "10:00:00"
  with fun post_lab_reply(_incident_id, message) message
  with fun wait_ms(_delay) ()
  val started = match handle_todo_click("edit-2", initial_model())
    Just(result) -> result
    Nothing -> initial_model()
  val (next_item, _panel_node, _effects, handlers) = run_todo_panel(started)
  match find_task_by_id(2, model_tasks(started))
    Nothing -> bool_result("Registered click handler stays local", "task #2 missing", False)
    Just(item) -> {
      val local_click_id = state_slot_path(named_listener_slot(task_hook_scope(item), Click_event, "cancel-edit"))
      val global_add_handler = find_registered_click(handlers, "add-task")
      match find_registered_click(handlers, local_click_id)
        Nothing -> bool_result("Registered click handler stays local", local_click_id ++ " missing", False)
        Just(found_click) -> {
          val updated = run_registered_click(found_click, next_item)
          val updated_task = match find_task_by_id(2, model_tasks(updated))
            Just(found) -> found
            Nothing -> item
          val editor_state = task_editor_snapshot(updated, updated_task)
          val has_global_add_handler = match global_add_handler
            Just(_) -> True
            Nothing -> False
          bool_result(
            "Registered click handler stays local",
            "clicks=" ++ count_registered_clicks(handlers).show ++ ", notice=" ++ model_notice(updated),
            not(has_global_add_handler) && not(task_editor_editing(editor_state)) && model_notice(updated) == "Cancelled local task edit.")
        }
    }

pub fun timer_simulation_test() : <div> test_result
  val (label, waits) = capture_waits(fn() timer_logic())
  val total = sum_ints(waits)
  val steps = count_ints(waits)
  bool_result("Timer simulation", steps.show ++ " waits / " ++ total.show ++ "ms / result=" ++ label, label == "timer-ready" && steps == 3 && total == 80)
