module demo/tests/basics

import demo/model
import demo/seed
import demo/tests/support
import demo/todopanel
import respo/core
import respo/renderer

fun timer_logic() : <wait_ms> string
  wait_ms(20)
  wait_ms(20)
  wait_ms(40)
  "timer-ready"

pub fun component_render_test() : <div> test_result
  val html = render_node("0", el("button", "sample", [class_attr("demo-button")], [click_listener("run-sample")], "Run", Nil))
  val expected = "<button data-kpath=\"0\" class=\"demo-button\" data-k-click=\"run-sample\">Run</button>"
  bool_result("Component render snapshot", if html == expected then "Stable HTML output for a small component." else html, html == expected)

pub fun confirm_decline_test() : <div> test_result
  with fun confirm_action(_message) False
  with fun audit(_message) ()
  val next = match handle_todo_click("remove-1", initial_model())
    Just(result) -> fst(result)
    Nothing -> initial_model()
  bool_result("Confirm decline keeps state", model_notice(next), count_all(model_tasks(next)) == 3)

pub fun confirm_accept_test() : <div> test_result
  with fun confirm_action(_message) True
  with fun audit(_message) ()
  val next = match handle_todo_click("remove-1", initial_model())
    Just(result) -> fst(result)
    Nothing -> initial_model()
  bool_result("Confirm accept removes task", "Remaining tasks: " ++ count_all(model_tasks(next)).show, count_all(model_tasks(next)) == 2)

pub fun ambient_filter_test() : <div> test_result
  val base = model_tasks(initial_model())
  val active_count = count_all(tasks_for("active", base))
  val done_count = count_all(tasks_for("done", base))
  bool_result("Ambient filter previews", "active=" ++ active_count.show ++ ", done=" ++ done_count.show, active_count == 2 && done_count == 1)

pub fun timer_simulation_test() : <div> test_result
  val (label, waits) = capture_waits(fn() timer_logic())
  val total = sum_ints(waits)
  val steps = count_ints(waits)
  bool_result("Timer simulation", steps.show ++ " waits / " ++ total.show ++ "ms / result=" ++ label, label == "timer-ready" && steps == 3 && total == 80)