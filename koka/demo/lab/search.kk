module demo/lab/search

import demo/bridge
import demo/model
import demo/seed

fun search_idle_note() : string
  "Type a query, pause to auto-search the menu catalog, keep stale results visible during refresh, and let timeout race against the mocked server response."

fun should_arm_auto_search(demo : search_demo, trimmed : string) : bool
  if trimmed == "" then
    False
  else if search_status(demo) == "ready" && trimmed == search_visible_query(demo) then
    False
  else if trimmed == search_requested_query(demo) && search_status(demo) != "idle" && search_status(demo) != "timed_out" then
    False
  else
    True

pub fun search_query_channel() : string
  "lab-search-query"

pub fun search_submit_payload() : string
  "lab-search-submit"

pub fun search_pick_payload(query : string) : string
  "lab-search-pick|" ++ query

pub fun decode_search_pick_payload(payload : string) : <div> maybe<string>
  match split(payload, "|")
    ["lab-search-pick", query] -> Just(query)
    _ -> Nothing

fun append_search_activity(lab : workflow_lab, line : string) : <div> workflow_lab
  lab(activity_log = lab_activity_log(lab) ++ [line])

pub fun set_search_query(owner : model, value : string) : <request_bridge_resource,div> model
  val lab = model_lab(owner)
  val demo = lab_search_demo(lab)
  val trimmed = trim(value)
  val should_arm = should_arm_auto_search(demo, trimmed)
  val next_auto_request_id = if should_arm then search_auto_request_id(demo) + 1 else search_auto_request_id(demo)
  val next_demo = demo(
    query_input = value,
    auto_status = if should_arm then "armed" else "idle",
    auto_request_id = next_auto_request_id,
    stage_note = if trimmed == "" then search_idle_note() else if should_arm then "Typing pause armed an automatic search. If no newer input arrives, the current menu query will start through the same suspense-lite bridge." else if search_status(demo) == "ready" && trimmed == search_visible_query(demo) then "Current visible menu results already match this query." else search_stage_note(demo))
  if should_arm then {
    request_bridge_result("search-auto", trimmed, next_auto_request_id, search_auto_delay())
    set_lab(owner, lab(search_demo = next_demo))
  }
  else
    set_lab(owner, lab(search_demo = next_demo))

fun start_search_query(owner : model, query : string) : <request_bridge_resource,audit,div> model
  val trimmed = trim(query)
  if trimmed == "" then
    set_notice(owner, "Search query is empty. Type a keyword before running the suspense-lite search demo.")
  else {
    val lab = model_lab(owner)
    val demo = lab_search_demo(lab)
    val next_request_id = search_request_id(demo) + 1
    val has_visible = search_visible_query(demo) != ""
    request_bridge_result("search", trimmed, next_request_id, search_result_delay(trimmed))
    request_bridge_result("search-timeout", trimmed, next_request_id, search_timeout_delay(trimmed))
    audit("Scheduled suspense-lite search for `" ++ trimmed ++ "`.")
    val next_demo = demo(
      query_input = trimmed,
      requested_query = trimmed,
      status = if has_visible then "refreshing" else "pending",
      timeout_status = "pending",
      auto_status = "idle",
      request_id = next_request_id,
      results = if has_visible then search_results(demo) else Nil,
      stage_note = if has_visible then "Refreshing search keeps the previous hit list visible until the newer query resolves or times out." else "Cold search enters a fallback while the mock server result races against the timeout budget.")
    val next_lab = append_search_activity(lab(search_demo = next_demo), "[search] pending for `" ++ trimmed ++ "`")
    set_notice(set_lab(owner, next_lab), if has_visible then "Search is refreshing while keeping stale results visible." else "Search entered a suspense-lite fallback state.")
  }

pub fun start_search(owner : model) : <request_bridge_resource,audit,div> model
  start_search_query(owner, search_query_input(lab_search_demo(model_lab(owner))))

pub fun pick_search_case(owner : model, query : string) : <request_bridge_resource,audit,div> model
  start_search_query(owner, query)

pub fun resolve_search_result(owner : model, payload : string) : <request_bridge_resource,audit,div> maybe<model>
  match decode_bridge_result_payload(payload)
    Just(Bridge_signal(resource_tag, query, request_id)) -> {
      if resource_tag != "bridge-search" && resource_tag != "bridge-search-timeout" && resource_tag != "bridge-search-auto" then
        Nothing
      else {
        val lab = model_lab(owner)
        val demo = lab_search_demo(lab)
        if resource_tag == "bridge-search-auto" then
          if search_auto_status(demo) != "armed" || request_id != search_auto_request_id(demo) || query != trim(search_query_input(demo)) then
            Just(owner)
          else if query == search_requested_query(demo) && search_status(demo) != "idle" && search_status(demo) != "timed_out" then
            Just(set_lab(owner, lab(search_demo = demo(auto_status = "idle"))))
          else
            Just(start_search_query(set_lab(owner, lab(search_demo = demo(auto_status = "idle"))), query))
        else if request_id != search_request_id(demo) || query != search_requested_query(demo) then
          Just(owner)
        else {
          if resource_tag == "bridge-search-timeout" then
            if search_status(demo) == "ready" then
              Just(owner)
            else {
              audit("Search timeout fired for `" ++ query ++ "`.")
              val has_visible = search_visible_query(demo) != ""
              val next_demo = demo(
                timeout_status = "timed_out",
                status = if has_visible then "refreshing" else "timed_out",
                stage_note = if has_visible then "Timeout fired, but stale hits stay on screen until the current response either recovers or gets replaced." else "Timeout fired before any search result became visible.")
              val next_lab = append_search_activity(lab(search_demo = next_demo), "[search] timeout for `" ++ query ++ "`")
              Just(set_notice(set_lab(owner, next_lab), if has_visible then "Search timeout fired; stale results remain visible." else "Search timed out before any result became visible."))
            }
          else {
            audit("Search results resolved for `" ++ query ++ "`.")
            val recovered = search_timeout_status(demo) == "timed_out"
            val next_demo = demo(
              query_input = query,
              visible_query = query,
              status = "ready",
              timeout_status = "idle",
              auto_status = "idle",
              results = search_result_lines(query),
              stage_note = if recovered then "Late server results recovered after the timeout banner had already appeared." else search_case_summary(query))
            val next_lab = append_search_activity(lab(search_demo = next_demo), "[search] ready for `" ++ query ++ "`")
            Just(set_notice(set_lab(owner, next_lab), if recovered then "Late search results recovered after timing out." else "Search results resolved through the suspense-lite bridge."))
          }
        }
      }
    }
    Nothing -> Nothing