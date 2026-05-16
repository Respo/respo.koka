module demo/tests

import demo/model
import demo/todopanel
import respo/core
import respo/renderer
import respo/state

pub struct test_result(name : string, detail : string, passed : bool)

pub fun test_name(item : test_result) : string
  match item
    Test_result(name, _, _) -> name

pub fun test_detail(item : test_result) : string
  match item
    Test_result(_, detail, _) -> detail

pub fun test_passed(item : test_result) : bool
  match item
    Test_result(_, _, passed) -> passed

fun bool_result(name : string, detail : string, passed : bool) : test_result
  Test_result(name, detail, passed)

fun append_int(xs : list<int>, value : int) : <div> list<int>
  match xs
    Nil -> [value]
    Cons(head, rest) -> Cons(head, append_int(rest, value))

fun count_ints(xs : list<int>) : <div> int
  match xs
    Nil -> 0
    Cons(_, rest) -> 1 + count_ints(rest)

fun count_strings(xs : list<string>) : <div> int
  match xs
    Nil -> 0
    Cons(_, rest) -> 1 + count_strings(rest)

fun count_patches(xs : list<patch>) : <div> int
  match xs
    Nil -> 0
    Cons(_, rest) -> 1 + count_patches(rest)

fun count_patch_kind(xs : list<patch>, target_kind : string) : <div> int
  match xs
    Nil -> 0
    Cons(item, rest) -> (if patch_kind(item) == target_kind then 1 else 0) + count_patch_kind(rest, target_kind)

fun maybe_text(target : maybe<string>) : string
  match target
    Just(name) -> name
    Nothing -> "<none>"

fun sum_ints(xs : list<int>) : <div> int
  match xs
    Nil -> 0
    Cons(head, rest) -> head + sum_ints(rest)

// Simulate timer-heavy logic instantly by handling `wait_ms` without touching the browser clock.
fun capture_waits(action : () -> <wait_ms|e> string) : e (string, list<int>)
  var waits := Nil
  with return(result) (result, waits)
  with fun wait_ms(delay) waits := Cons(delay, waits)
  action()

fun capture_workflow(action : () -> <wait_ms,fetch_lab_snapshot,post_lab_reply,now_label,audit,current_operator|e> model) : e (model, list<int>, list<string>)
  var waits := Nil
  var audits := Nil
  with return(result) (result, waits, audits)
  with val current_operator = "test-operator"
  with fun wait_ms(delay) waits := Cons(delay, waits)
  with fun fetch_lab_snapshot() mock_lab_snapshot()
  with fun post_lab_reply(incident_id, message) mock_lab_reply(incident_id, message)
  with fun now_label() "T+120"
  with fun audit(message) audits := Cons(message, audits)
  action()

fun timer_logic() : <wait_ms> string
  wait_ms(20)
  wait_ms(20)
  wait_ms(40)
  "timer-ready"

fun component_render_test() : <div> test_result
  val html = render_node("0", el("button", "sample", [class_attr("demo-button")], [click_listener("run-sample")], "Run", Nil))
  val expected = "<button data-kpath=\"0\" class=\"demo-button\" data-k-click=\"run-sample\">Run</button>"
  bool_result("Component render snapshot", if html == expected then "Stable HTML output for a small component." else html, html == expected)

fun confirm_decline_test() : <div> test_result
  with fun confirm_action(_message) False
  with fun audit(_message) ()
  val next = handle_remove(initial_model(), "remove-1")
  bool_result("Confirm decline keeps state", model_notice(next), count_all(model_tasks(next)) == 3)

fun confirm_accept_test() : <div> test_result
  with fun confirm_action(_message) True
  with fun audit(_message) ()
  val next = handle_remove(initial_model(), "remove-1")
  bool_result("Confirm accept removes task", "Remaining tasks: " ++ count_all(model_tasks(next)).show, count_all(model_tasks(next)) == 2)

fun ambient_filter_test() : <div> test_result
  val base = model_tasks(initial_model())
  val active_count = count_all(tasks_for("active", base))
  val done_count = count_all(tasks_for("done", base))
  bool_result("Ambient filter previews", "active=" ++ active_count.show ++ ", done=" ++ done_count.show, active_count == 2 && done_count == 1)

fun timer_simulation_test() : <div> test_result
  val (label, waits) = capture_waits(fn() timer_logic())
  val total = sum_ints(waits)
  val steps = count_ints(waits)
  bool_result("Timer simulation", steps.show ++ " waits / " ++ total.show ++ "ms / result=" ++ label, label == "timer-ready" && steps == 3 && total == 80)

fun state_tree_test() : <div> test_result
  val tree = assoc_flag(assoc_text(Nil, "lab/incidents/101/draft", "Shift traffic to backup POP."), "lab/incidents/101/expanded", True)
  val draft = state_text(tree, "lab/incidents/101/draft", "")
  val expanded = state_flag(tree, "lab/incidents/101/expanded", False)
  bool_result("State tree local state", "draft=" ++ draft ++ ", expanded=" ++ expanded.show, draft == "Shift traffic to backup POP." && expanded)

fun todo_edit_local_state_test() : <div> test_result
  with fun audit(_message) ()
  val (started, _focus_target) = start_task_edit(initial_model(), 2)
  val drafted = set_task_edit_draft(started, 2, "Prototype local title edits before save")
  val saved = save_task_edit(drafted, 2)
  val title = match find_task_by_id(2, model_tasks(saved))
    Just(item) -> task_title(item)
    Nothing -> "missing"
  val local_entries = count_entries(model_todo_local_tree(saved))
  bool_result(
    "Todo item local editing",
    "title=" ++ title ++ ", local=" ++ local_entries.show ++ ", editing=" ++ task_is_editing(started, 2).show,
    title == "Prototype local title edits before save" && local_entries == 0 && not(task_is_editing(saved, 2)))

fun todo_edit_diff_test() : <div> test_result
  with fun audit(_message) ()
  val (started, _focus_target) = start_task_edit(initial_model(), 2)
  val drafted = set_task_edit_draft(started, 2, "x")
  val patches = diff_node("0", todo_panel(started), todo_panel(drafted))
  bool_result(
    "Todo draft uses attribute patch",
    "patches=" ++ count_patches(patches).show ++ ", attrs=" ++ count_patch_kind(patches, "set-attr").show ++ ", replace=" ++ count_patch_kind(patches, "replace").show,
    count_patch_kind(patches, "set-attr") == 1 && count_patch_kind(patches, "replace") == 0)

fun add_task_focus_test() : <div> test_result
  with fun audit(_message) ()
  val seeded = set_draft(initial_model(), "Queue a fresh task")
  val (next, target) = add_task(seeded)
  val focused_draft = match target
    Just(field_name) -> field_name == "draft"
    Nothing -> False
  bool_result("Add task schedules focus", "draft=" ++ model_draft(next) ++ ", target=" ++ maybe_text(target), model_draft(next) == "" && focused_draft)

fun start_edit_focus_test() : <div> test_result
  with fun audit(_message) ()
  val (next, target) = start_task_edit(initial_model(), 2)
  val expected = match find_task_by_id(2, model_tasks(next))
    Just(item) -> task_draft_channel(item)
    Nothing -> "missing"
  val focused_editor = match target
    Just(field_name) -> field_name == expected
    Nothing -> False
  bool_result("Start edit schedules focus", "expected=" ++ expected ++ ", target=" ++ maybe_text(target), task_is_editing(next, 2) && focused_editor)

fun workflow_sync_test() : <div> test_result
  val (next, waits, audits) = capture_workflow(fn() perform_lab_sync(set_route(initial_model(), "lab")))
  val total = sum_ints(waits)
  val lab = model_lab(next)
  bool_result(
    "Workflow sync captures waits",
    "incidents=" ++ lab_incident_count(lab).show ++ ", waits=" ++ total.show ++ "ms, audits=" ++ count_strings(audits).show ++ ", sync=" ++ lab_last_sync_label(lab),
    lab_incident_count(lab) == 3 && total == 120 && count_strings(audits) == 1 && lab_last_sync_label(lab) == "T+120")

fun workflow_reply_test() : <div> test_result
  val prepared = set_lab_draft(set_route(initial_model(), "lab"), 102, "Shift replay traffic onto the cache-safe queue.")
  val (next, waits, _audits) = capture_workflow(fn() send_lab_reply(prepared, 102))
  val total = sum_ints(waits)
  val lab = model_lab(next)
  val cleared = incident_draft(lab, 102) == ""
  val acked = match lab_incident_by_id(lab, 102)
    Just(item) -> incident_status(item) == "acked" && incident_server_note(item) == "Shift replay traffic onto the cache-safe queue."
    Nothing -> False
  bool_result("Workflow reply clears local draft", "waits=" ++ total.show ++ "ms, drafts=" ++ lab_draft_count(lab).show ++ ", status=" ++ lab_sync_status(lab), cleared && acked && total == 60)

pub fun demo_test_results() : <div> list<test_result>
  [
    component_render_test(),
    confirm_decline_test(),
    confirm_accept_test(),
    ambient_filter_test(),
    timer_simulation_test(),
    state_tree_test(),
    add_task_focus_test(),
    start_edit_focus_test(),
    todo_edit_local_state_test(),
    todo_edit_diff_test(),
    workflow_sync_test(),
    workflow_reply_test(),
  ]

pub fun passed_count(results : list<test_result>) : <div> int
  match results
    Nil -> 0
    Cons(item, rest) -> (if test_passed(item) then 1 else 0) + passed_count(rest)

pub fun total_count(results : list<test_result>) : <div> int
  match results
    Nil -> 0
    Cons(_, rest) -> 1 + total_count(rest)

pub fun find_result(name : string, results : list<test_result>) : <div> maybe<test_result>
  match results
    Nil -> Nothing
    Cons(item, rest) -> if test_name(item) == name then Just(item) else find_result(name, rest)
