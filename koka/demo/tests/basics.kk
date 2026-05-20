module demo/tests/basics

import library/bridge
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
  val html = render_node("0", button([class_attr("demo-button")], [click_listener("run-sample")], "Run"))
  val expected = "<button data-kpath=\"0\" class=\"demo-button\" data-k-click=\"run-sample\">Run</button>"
  Test_result("Component render snapshot", if html == expected then "Stable HTML output for a small component." else html, html == expected)

pub fun confirm_decline_test() : <div> test_result
  with fun confirm_action(_message) False
  with fun audit(_message) ()
  val next = match handle_todo_click("remove-1", initial_model())
    Just(result) -> result
    Nothing -> initial_model()
  Test_result("Confirm decline keeps state", next.notice, length(next.tasks) == 3)

pub fun confirm_accept_test() : <div> test_result
  with fun confirm_action(_message) True
  with fun audit(_message) ()
  val next = match handle_todo_click("remove-1", initial_model())
    Just(result) -> result
    Nothing -> initial_model()
  Test_result("Confirm accept removes task", "Remaining tasks: " ++ length(next.tasks).show, length(next.tasks) == 2)

pub fun ambient_filter_test() : <div> test_result
  val base = initial_model().tasks
  val active_count = length(tasks_for("active", base))
  val done_count = length(tasks_for("done", base))
  Test_result("Ambient filter previews", "active=" ++ active_count.show ++ ", done=" ++ done_count.show, active_count == 2 && done_count == 1)

pub fun registered_input_handler_test() : <div> test_result
  val target_id = state_slot/path(named_listener_slot(todo_effect_scope(), Input_event, "draft-input"))
  val (next_item, _panel_node, _effects, handlers) = run_todo_panel(initial_model())
  match find_registered_input(handlers, target_id)
    Just(found_input) -> {
      val updated = run_registered_input(found_input, "closure draft", next_item)
      Test_result("Registered input handler updates draft", "inputs=" ++ count_registered_inputs(handlers).show ++ ", draft=" ++ updated.draft, updated.draft == "closure draft")
    }
    Nothing -> Test_result("Registered input handler updates draft", target_id ++ " missing", False)

pub fun registered_click_handler_test() : <div> test_result
  with fun confirm_action(_message) False
  with fun audit(_message) ()
  with val current_operator = "test-operator"
  with fun fetch_lab_snapshot() Lab_snapshot(Nil, "empty")
  with fun now_label() "10:00:00"
  with fun post_lab_reply(_incident_id, message) message
  with fun request_bridge_resource(_payload, _delay) ()
  with fun wait_ms(_delay) ()
  val started = match handle_todo_click("edit-2", initial_model())
    Just(result) -> result
    Nothing -> initial_model()
  val (next_item, _panel_node, _effects, handlers) = run_todo_panel(started)
  match find(started.tasks, fn(item) 2 == task/id(item))
    Nothing -> Test_result("Registered click handler stays local", "task #2 missing", False)
    Just(item) -> {
      val local_click_id = state_slot/path(named_listener_slot(task_hook_scope(item), Click_event, "cancel-edit"))
      val global_add_handler = find_registered_click(handlers, "add-task")
      match find_registered_click(handlers, local_click_id)
        Nothing -> Test_result("Registered click handler stays local", local_click_id ++ " missing", False)
        Just(found_click) -> {
          val updated = run_registered_click(found_click, next_item)
          val updated_task = match find(updated.tasks, fn(task_item) 2 == task/id(task_item))
            Just(found) -> found
            Nothing -> item
          val editor_state = snapshot_task_editor(updated, updated_task)
          val has_global_add_handler = match global_add_handler
            Just(_) -> True
            Nothing -> False
          Test_result(
            "Registered click handler stays local",
            "clicks=" ++ count_registered_clicks(handlers).show ++ ", notice=" ++ updated.notice,
            not(has_global_add_handler) && not(task_editor_state/editing(editor_state)) && updated.notice == "Cancelled local task edit.")
        }
    }

pub fun timer_simulation_test() : <div> test_result
  val (label, waits) = capture_waits(fn() timer_logic())
  val total = sum(waits)
  val steps = length(waits)
  Test_result("Timer simulation", steps.show ++ " waits / " ++ total.show ++ "ms / result=" ++ label, label == "timer-ready" && steps == 3 && total == 80)

pub fun route_subroute_normalization_test() : <div> test_result
  with fun confirm_action(_message) False
  with fun audit(_message) ()
  with val current_operator = "test-operator"
  with fun fetch_lab_snapshot() mock_lab_snapshot()
  with fun now_label() "10:00:00"
  with fun post_lab_reply(_incident_id, message) message
  with fun request_bridge_resource(_payload, _delay) ()
  with fun wait_ms(_delay) ()
  val lab_route = reduce_click("route-lab-search", initial_model()).route_name
  val effects_route = reduce_click("route-effects-dialogs", initial_model()).route_name
  val legacy_lab = normalize_route("lab")
  val legacy_effects = normalize_route("effects")
  Test_result(
    "Route subpages normalize",
    "lab=" ++ lab_route ++ ", effects=" ++ effects_route ++ ", legacy=" ++ legacy_lab ++ "/" ++ legacy_effects,
    lab_route == "lab-search" && effects_route == "effects-dialogs" && legacy_lab == "lab-board" && legacy_effects == "effects-core")

// --- Component harness tests ---
// These tests exercise components by navigating the vnode tree, reading event
// attributes, and firing handlers through the registry - mirroring how the browser
// delegates DOM events, without needing a real DOM.

// Verify that a button's data-k-click value and the registry agree: the payload
// visible in the rendered HTML is the same key that resolves to a live handler.
pub fun vnode_click_payload_matches_registry_test() : <div> test_result
  with fun confirm_action(_) False
  with fun audit(_) ()
  with val current_operator = "test-operator"
  with fun fetch_lab_snapshot() Lab_snapshot(Nil, "empty")
  with fun now_label() "T+0"
  with fun post_lab_reply(_id, msg) msg
  with fun request_bridge_resource(_p, _d) ()
  with fun wait_ms(_d) ()
  val editing = match handle_todo_click("edit-2", initial_model())
    Just(r) -> r
    Nothing -> initial_model()
  val (_, tree, _, registry) = run_todo_panel(editing)
  val cancel_node_payload = match vnode_find_text(tree, "Cancel")
    Just(node) -> vnode_click_payload(node)
    Nothing -> ""
  val in_registry = match find_registered_click(registry, cancel_node_payload)
    Just(_) -> True
    Nothing -> False
  Test_result(
    "Vnode click payload matches registry",
    "payload=" ++ cancel_node_payload ++ ", in_registry=" ++ in_registry.show,
    cancel_node_payload != "" && in_registry)

// Verify that firing the "cancel-edit" handler via harness produces the same
// outcome as the low-level slot-path lookup in registered_click_handler_test.
pub fun harness_cancel_edit_test() : <div> test_result
  with fun confirm_action(_) False
  with fun audit(_) ()
  with val current_operator = "test-operator"
  with fun fetch_lab_snapshot() Lab_snapshot(Nil, "empty")
  with fun now_label() "T+0"
  with fun post_lab_reply(_id, msg) msg
  with fun request_bridge_resource(_p, _d) ()
  with fun wait_ms(_d) ()
  val editing = match handle_todo_click("edit-2", initial_model())
    Just(r) -> r
    Nothing -> initial_model()
  val h0 = todo_harness(editing)
  val h1 = harness_fire_named_click(h0, "cancel-edit", todo_harness)
  val editor_state = match find(h1.owner.tasks, fn(item) 2 == task/id(item))
    Just(item) -> snapshot_task_editor(h1.owner, item)
    Nothing -> Task_editor_state(False, "")
  Test_result(
    "Harness cancel-edit via semantic handler",
    "notice=" ++ h1.owner.notice ++ ", editing=" ++ task_editor_state/editing(editor_state).show,
    h1.owner.notice == "Cancelled local task edit." && not(task_editor_state/editing(editor_state)))

// Verify that an input event fired via harness updates the model and is reflected
// in the re-rendered vnode's value attribute.
pub fun harness_draft_input_test() : <div> test_result
  val h0 = todo_harness(initial_model())
  val h1 = harness_fire_named_input(h0, "draft-input", "typed via harness", todo_harness)
  val input_value = match vnode_find_attr_value(h1.tree, "data-k-effect", "draft")
    Just(node) -> vnode_get_attr(node, "value")
    Nothing -> "node-missing"
  Test_result(
    "Harness input updates model and vnode",
    "draft=" ++ h1.owner.draft ++ ", input-value=" ++ input_value,
    h1.owner.draft == "typed via harness" && input_value == "typed via harness")

// Multi-step: type into draft, then fire cancel-edit on a task being edited.
// Verifies that two sequential harness steps compose correctly.
pub fun harness_multi_step_test() : <div> test_result
  with fun confirm_action(_) False
  with fun audit(_) ()
  with val current_operator = "test-operator"
  with fun fetch_lab_snapshot() Lab_snapshot(Nil, "empty")
  with fun now_label() "T+0"
  with fun post_lab_reply(_id, msg) msg
  with fun request_bridge_resource(_p, _d) ()
  with fun wait_ms(_d) ()
  val editing = match handle_todo_click("edit-2", initial_model())
    Just(r) -> r
    Nothing -> initial_model()
  val h0 = todo_harness(editing)
  // Step 1: type into the panel draft field
  val h1 = harness_fire_named_input(h0, "draft-input", "step1 draft", todo_harness)
  // Step 2: cancel the task edit via local handler
  val h2 = harness_fire_named_click(h1, "cancel-edit", todo_harness)
  val editor_state = match find(h2.owner.tasks, fn(item) 2 == task/id(item))
    Just(item) -> snapshot_task_editor(h2.owner, item)
    Nothing -> Task_editor_state(False, "")
  Test_result(
    "Harness multi-step input then click",
    "draft=" ++ h2.owner.draft ++ ", notice=" ++ h2.owner.notice ++ ", editing=" ++ task_editor_state/editing(editor_state).show,
    h2.owner.draft == "step1 draft" && h2.owner.notice == "Cancelled local task edit." && not(task_editor_state/editing(editor_state)))
