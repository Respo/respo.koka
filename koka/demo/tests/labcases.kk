module demo/tests/labcases

import demo/model
import demo/seed
import demo/lab/state
import demo/lab/workflow
import demo/labpanel
import demo/tests/support

pub fun lab_local_routing_test() : <div> test_result
  with val current_operator = "test-operator"
  with fun wait_ms(_delay) ()
  with fun fetch_lab_snapshot() mock_lab_snapshot()
  with fun post_lab_reply(incident_id, message) mock_lab_reply(incident_id, message)
  with fun now_label() "T+120"
  with fun audit(_message) ()
  val base = set_route(initial_model(), "lab")
  val drafted = match handle_lab_input("lab-draft-101", "Shift traffic to backup POP.", base)
    Just(result) -> result
    Nothing -> base
  val toggled = match handle_lab_click("lab-toggle-101", drafted)
    Just(result) -> result
    Nothing -> drafted
  val lab = model_lab(toggled)
  Test_result("Workflow lab local routing", "draft=" ++ lab_incident_draft(lab, 101) ++ ", expanded=" ++ lab_incident_expanded(lab, 101).show, lab_incident_draft(lab, 101) == "Shift traffic to backup POP." && lab_incident_expanded(lab, 101))

pub fun workflow_sync_test() : <div> test_result
  val (next, waits, audits) = capture_workflow(fn() perform_sync(set_route(initial_model(), "lab")))
  val total = sum(waits)
  val lab = model_lab(next)
  Test_result(
    "Workflow sync captures waits",
    "incidents=" ++ lab_incident_count(lab).show ++ ", waits=" ++ total.show ++ "ms, audits=" ++ length(audits).show ++ ", sync=" ++ lab_last_sync_label(lab),
    lab_incident_count(lab) == 3 && total == 120 && length(audits) == 1 && lab_last_sync_label(lab) == "T+120")

pub fun workflow_reply_test() : <div> test_result
  val base = set_route(initial_model(), "lab")
  val prepared = commit_lab_tree(base, fn() set_local_lab_draft(base, 102, "Shift replay traffic onto the cache-safe queue."))
  val (next, waits, _audits) = capture_workflow(fn() send_reply(prepared, 102))
  val total = sum(waits)
  val lab = model_lab(next)
  val cleared = lab_incident_draft(lab, 102) == ""
  val acked = match lab_incident_by_id(lab, 102)
    Just(item) -> incident_status(item) == "acked" && incident_server_note(item) == "Shift replay traffic onto the cache-safe queue."
    Nothing -> False
  Test_result("Workflow reply clears local draft", "waits=" ++ total.show ++ "ms, drafts=" ++ lab_draft_count(lab).show ++ ", status=" ++ lab_sync_status(lab), cleared && acked && total == 60)