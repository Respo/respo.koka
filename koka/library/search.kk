module library/search

pub struct search_demo
  query_input : string
  requested_query : string
  visible_query : string
  status : string
  timeout_status : string
  auto_status : string
  request_id : int
  auto_request_id : int
  results : list<string>
  stage_note : string

pub fun initial_search_demo(query_input : string, stage_note : string) : search_demo
  Search_demo(query_input, "", "", "idle", "idle", "idle", 0, 0, Nil, stage_note)

pub fun should_arm_auto_search(demo : search_demo, trimmed : string) : bool
  if trimmed == "" then
    False
  else if demo.status == "ready" && trimmed == demo.visible_query then
    False
  else if trimmed == demo.requested_query && demo.status != "idle" && demo.status != "timed_out" then
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