module demo/tests/searchcases

import demo/model
import demo/tests/support

pub fun search_auto_timer_armed_test() : <div> test_result
  val (typed, requests, audits) = capture_search_input(search_base_model(), "queue")
  val demo = typed.lab.search_demo
  Test_result(
    "Search input arms auto timer",
    "auto=" ++ demo.auto_status ++ ", requests=" ++ length(requests).show ++ ", query=" ++ demo.query_input,
    length(requests) == 1 && first_text(requests) == "bridge-search-auto|queue|1@240" && length(audits) == 0 && demo.auto_status == "armed" && demo.status == "idle")

pub fun search_auto_timer_starts_pending_test() : <div> test_result
  val (typed, _input_requests, _input_audits) = capture_search_input(search_base_model(), "queue")
  val (started, requests, audits) = capture_search_auto(typed, "queue", 1)
  val demo = started.lab.search_demo
  val has_result_request = any(requests, fn(item) item == "bridge-search|queue|1@760")
  val has_timeout_request = any(requests, fn(item) item == "bridge-search-timeout|queue|1@320")
  Test_result(
    "Search auto timer starts pending request",
    "status=" ++ demo.status ++ ", auto=" ++ demo.auto_status ++ ", requests=" ++ length(requests).show,
    length(requests) == 2 && length(audits) == 1 && has_result_request && has_timeout_request && demo.status == "pending" && demo.auto_status == "idle")

pub fun search_stale_auto_ignored_test() : <div> test_result
  val (typed, _requests_1, _audits_1) = capture_search_input(search_base_model(), "queue")
  val (retargeted, _requests_2, _audits_2) = capture_search_input(typed, "queue ")
  val (ignored, requests, audits) = capture_search_auto(retargeted, "queue", 1)
  val demo = ignored.lab.search_demo
  Test_result(
    "Search ignores stale auto timer after newer input",
    "auto=" ++ demo.auto_status ++ ", auto-id=" ++ demo.auto_request_id.show ++ ", requests=" ++ length(requests).show,
    length(requests) == 0 && length(audits) == 0 && demo.auto_status == "armed" && demo.auto_request_id == 2)

pub fun search_pending_test() : <div> test_result
  val (next, requests, audits) = capture_search_submit(search_base_model())
  val demo = next.lab.search_demo
  val has_result_request = any(requests, fn(item) item == "bridge-search|edge|1@180")
  val has_timeout_request = any(requests, fn(item) item == "bridge-search-timeout|edge|1@420")
  Test_result(
    "Search demo enters pending",
    "requests=" ++ length(requests).show ++ ", status=" ++ demo.status ++ ", timeout=" ++ demo.timeout_status,
    length(requests) == 2 && length(audits) == 1 && has_result_request && has_timeout_request && demo.status == "pending" && demo.timeout_status == "pending" && demo.visible_query == "" && demo.auto_status == "idle")

pub fun search_resolve_before_timeout_test() : <div> test_result
  val (started, _requests, _audits) = capture_search_submit(search_base_model())
  val (resolved, stale_requests, audits) = capture_search_result(started, "edge", 1)
  val demo = resolved.lab.search_demo
  Test_result(
    "Search resolves before timeout",
    "visible=" ++ demo.visible_query ++ ", status=" ++ demo.status ++ ", first=" ++ first_text(demo.results),
    demo.visible_query == "edge" && demo.status == "ready" && demo.timeout_status == "idle" && length(demo.results) == 2 && first_text(demo.results) == "Edge auth bundle -> #lab-bridge | Staged shell/detail bridge around auth drift at the edge POPs." && length(stale_requests) == 0 && length(audits) == 1)

pub fun search_timeout_then_recover_test() : <div> test_result
  val typed = search_input(search_base_model(), "queue")
  val (started, _requests, _audits) = capture_search_submit(typed)
  val (timed_out, _timeout_requests, timeout_audits) = capture_search_timeout(started, "queue", 1)
  val (recovered, _result_requests, result_audits) = capture_search_result(timed_out, "queue", 1)
  val timeout_demo = timed_out.lab.search_demo
  val recovered_demo = recovered.lab.search_demo
  Test_result(
    "Search recovers after timeout",
    "timeout-status=" ++ timeout_demo.status ++ ", recovered=" ++ recovered_demo.status ++ ", visible=" ++ recovered_demo.visible_query,
    timeout_demo.status == "timed_out" && timeout_demo.timeout_status == "timed_out" && recovered_demo.status == "ready" && recovered_demo.timeout_status == "idle" && recovered_demo.visible_query == "queue" && length(recovered_demo.results) == 2 && length(timeout_audits) == 1 && length(result_audits) == 1)

pub fun search_refresh_keeps_visible_test() : <div> test_result
  val edge_ready = {
    val (started, _requests, _audits) = capture_search_submit(search_base_model())
    val (resolved, _result_requests, _result_audits) = capture_search_result(started, "edge", 1)
    resolved
  }
  val typed = search_input(edge_ready, "image")
  val (refreshing, requests, audits) = capture_search_submit(typed)
  val demo = refreshing.lab.search_demo
  Test_result(
    "Search refresh keeps stale hits visible",
    "visible=" ++ demo.visible_query ++ ", requested=" ++ demo.requested_query ++ ", status=" ++ demo.status,
    length(requests) == 2 && length(audits) == 1 && demo.visible_query == "edge" && demo.requested_query == "image" && demo.status == "refreshing" && length(demo.results) == 2)

pub fun search_stale_timeout_ignored_test() : <div> test_result
  val typed = search_input(search_base_model(), "queue")
  val (queue_started, _queue_requests, _queue_audits) = capture_search_submit(typed)
  val retargeted = search_input(queue_started, "edge")
  val (edge_started, _edge_requests, _edge_audits) = capture_search_submit(retargeted)
  val (ignored, requests, audits) = capture_search_timeout(edge_started, "queue", 1)
  val demo = ignored.lab.search_demo
  Test_result(
    "Search ignores stale timeout after retarget",
    "requested=" ++ demo.requested_query ++ ", status=" ++ demo.status ++ ", requests=" ++ length(requests).show,
    length(requests) == 0 && length(audits) == 0 && demo.requested_query == "edge" && demo.status == "pending")

pub fun search_stale_result_ignored_test() : <div> test_result
  val typed = search_input(search_base_model(), "queue")
  val (queue_started, _queue_requests, _queue_audits) = capture_search_submit(typed)
  val retargeted = search_input(queue_started, "edge")
  val (edge_started, _edge_requests, _edge_audits) = capture_search_submit(retargeted)
  val (ignored, requests, audits) = capture_search_result(edge_started, "queue", 1)
  val demo = ignored.lab.search_demo
  Test_result(
    "Search ignores stale result after retarget",
    "requested=" ++ demo.requested_query ++ ", status=" ++ demo.status ++ ", requests=" ++ length(requests).show,
    length(requests) == 0 && length(audits) == 0 && demo.requested_query == "edge" && demo.status == "pending")