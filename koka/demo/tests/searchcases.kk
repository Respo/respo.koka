module demo/tests/searchcases

import demo/model
import demo/tests/support

pub fun search_auto_timer_armed_test() : <div> test_result
  val (typed, requests, audits) = capture_search_input(search_base_model(), "queue")
  val demo = lab_search_demo(model_lab(typed))
  Test_result(
    "Search input arms auto timer",
    "auto=" ++ search_auto_status(demo) ++ ", requests=" ++ length(requests).show ++ ", query=" ++ search_query_input(demo),
    length(requests) == 1 && first_text(requests) == "bridge-search-auto|queue|1@240" && length(audits) == 0 && search_auto_status(demo) == "armed" && search_status(demo) == "idle")

pub fun search_auto_timer_starts_pending_test() : <div> test_result
  val (typed, _input_requests, _input_audits) = capture_search_input(search_base_model(), "queue")
  val (started, requests, audits) = capture_search_auto(typed, "queue", 1)
  val demo = lab_search_demo(model_lab(started))
  val has_result_request = any(requests, fn(item) item == "bridge-search|queue|1@760")
  val has_timeout_request = any(requests, fn(item) item == "bridge-search-timeout|queue|1@320")
  Test_result(
    "Search auto timer starts pending request",
    "status=" ++ search_status(demo) ++ ", auto=" ++ search_auto_status(demo) ++ ", requests=" ++ length(requests).show,
    length(requests) == 2 && length(audits) == 1 && has_result_request && has_timeout_request && search_status(demo) == "pending" && search_auto_status(demo) == "idle")

pub fun search_stale_auto_ignored_test() : <div> test_result
  val (typed, _requests_1, _audits_1) = capture_search_input(search_base_model(), "queue")
  val (retargeted, _requests_2, _audits_2) = capture_search_input(typed, "queue ")
  val (ignored, requests, audits) = capture_search_auto(retargeted, "queue", 1)
  val demo = lab_search_demo(model_lab(ignored))
  Test_result(
    "Search ignores stale auto timer after newer input",
    "auto=" ++ search_auto_status(demo) ++ ", auto-id=" ++ search_auto_request_id(demo).show ++ ", requests=" ++ length(requests).show,
    length(requests) == 0 && length(audits) == 0 && search_auto_status(demo) == "armed" && search_auto_request_id(demo) == 2)

pub fun search_pending_test() : <div> test_result
  val (next, requests, audits) = capture_search_submit(search_base_model())
  val demo = lab_search_demo(model_lab(next))
  val has_result_request = any(requests, fn(item) item == "bridge-search|edge|1@180")
  val has_timeout_request = any(requests, fn(item) item == "bridge-search-timeout|edge|1@420")
  Test_result(
    "Search demo enters pending",
    "requests=" ++ length(requests).show ++ ", status=" ++ search_status(demo) ++ ", timeout=" ++ search_timeout_status(demo),
    length(requests) == 2 && length(audits) == 1 && has_result_request && has_timeout_request && search_status(demo) == "pending" && search_timeout_status(demo) == "pending" && search_visible_query(demo) == "" && search_auto_status(demo) == "idle")

pub fun search_resolve_before_timeout_test() : <div> test_result
  val (started, _requests, _audits) = capture_search_submit(search_base_model())
  val (resolved, stale_requests, audits) = capture_search_result(started, "edge", 1)
  val demo = lab_search_demo(model_lab(resolved))
  Test_result(
    "Search resolves before timeout",
    "visible=" ++ search_visible_query(demo) ++ ", status=" ++ search_status(demo) ++ ", first=" ++ first_text(search_results(demo)),
    search_visible_query(demo) == "edge" && search_status(demo) == "ready" && search_timeout_status(demo) == "idle" && length(search_results(demo)) == 2 && first_text(search_results(demo)) == "Edge auth bundle -> /lab/bridge/edge-auth | Staged shell/detail bridge around auth drift at the edge POPs." && length(stale_requests) == 0 && length(audits) == 1)

pub fun search_timeout_then_recover_test() : <div> test_result
  val typed = search_input(search_base_model(), "queue")
  val (started, _requests, _audits) = capture_search_submit(typed)
  val (timed_out, _timeout_requests, timeout_audits) = capture_search_timeout(started, "queue", 1)
  val (recovered, _result_requests, result_audits) = capture_search_result(timed_out, "queue", 1)
  val timeout_demo = lab_search_demo(model_lab(timed_out))
  val recovered_demo = lab_search_demo(model_lab(recovered))
  Test_result(
    "Search recovers after timeout",
    "timeout-status=" ++ search_status(timeout_demo) ++ ", recovered=" ++ search_status(recovered_demo) ++ ", visible=" ++ search_visible_query(recovered_demo),
    search_status(timeout_demo) == "timed_out" && search_timeout_status(timeout_demo) == "timed_out" && search_status(recovered_demo) == "ready" && search_timeout_status(recovered_demo) == "idle" && search_visible_query(recovered_demo) == "queue" && length(search_results(recovered_demo)) == 2 && length(timeout_audits) == 1 && length(result_audits) == 1)

pub fun search_refresh_keeps_visible_test() : <div> test_result
  val edge_ready = {
    val (started, _requests, _audits) = capture_search_submit(search_base_model())
    val (resolved, _result_requests, _result_audits) = capture_search_result(started, "edge", 1)
    resolved
  }
  val typed = search_input(edge_ready, "image")
  val (refreshing, requests, audits) = capture_search_submit(typed)
  val demo = lab_search_demo(model_lab(refreshing))
  Test_result(
    "Search refresh keeps stale hits visible",
    "visible=" ++ search_visible_query(demo) ++ ", requested=" ++ search_requested_query(demo) ++ ", status=" ++ search_status(demo),
    length(requests) == 2 && length(audits) == 1 && search_visible_query(demo) == "edge" && search_requested_query(demo) == "image" && search_status(demo) == "refreshing" && length(search_results(demo)) == 2)

pub fun search_stale_timeout_ignored_test() : <div> test_result
  val typed = search_input(search_base_model(), "queue")
  val (queue_started, _queue_requests, _queue_audits) = capture_search_submit(typed)
  val retargeted = search_input(queue_started, "edge")
  val (edge_started, _edge_requests, _edge_audits) = capture_search_submit(retargeted)
  val (ignored, requests, audits) = capture_search_timeout(edge_started, "queue", 1)
  val demo = lab_search_demo(model_lab(ignored))
  Test_result(
    "Search ignores stale timeout after retarget",
    "requested=" ++ search_requested_query(demo) ++ ", status=" ++ search_status(demo) ++ ", requests=" ++ length(requests).show,
    length(requests) == 0 && length(audits) == 0 && search_requested_query(demo) == "edge" && search_status(demo) == "pending")

pub fun search_stale_result_ignored_test() : <div> test_result
  val typed = search_input(search_base_model(), "queue")
  val (queue_started, _queue_requests, _queue_audits) = capture_search_submit(typed)
  val retargeted = search_input(queue_started, "edge")
  val (edge_started, _edge_requests, _edge_audits) = capture_search_submit(retargeted)
  val (ignored, requests, audits) = capture_search_result(edge_started, "queue", 1)
  val demo = lab_search_demo(model_lab(ignored))
  Test_result(
    "Search ignores stale result after retarget",
    "requested=" ++ search_requested_query(demo) ++ ", status=" ++ search_status(demo) ++ ", requests=" ++ length(requests).show,
    length(requests) == 0 && length(audits) == 0 && search_requested_query(demo) == "edge" && search_status(demo) == "pending")