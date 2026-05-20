module library/search

import respo/core

pub struct search_case
  query : string
  label : string
  summary : string
  result_delay : int
  timeout_delay : int

pub struct search_menu_item
  title : string
  route_hint : string
  note : string
  query_hint : string
  keywords : list<string>

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

fun search_cases() : list<search_case>
  [
    Search_case(
      "edge",
      "Edge cache",
      "Fast enough to beat the timeout budget, useful for the happy path.",
      180,
      420),
    Search_case(
      "queue",
      "Replay queue",
      "Timeout wins first, then the server result recovers later.",
      760,
      320),
    Search_case(
      "image",
      "Image burst",
      "Near-threshold latency to exercise interleaving and stale ignore cases.",
      460,
      300),
    Search_case(
      "dialog",
      "Dialog overlay",
      "Extra catalog keyword that proves search results now come from menu data instead of hardcoded copy.",
      280,
      360),
  ]

fun menu_catalog() : list<search_menu_item>
  [
    Search_menu_item(
      "Edge auth bundle",
      "#lab-bridge",
      "Staged shell/detail bridge around auth drift at the edge POPs.",
      "edge",
      ["edge", "auth", "cache", "login"]),
    Search_menu_item(
      "Edge rollout timeline",
      "#lab-bridge",
      "Transition timeline for warmup, rollout, and stale-shell recovery.",
      "edge",
      ["edge", "rollout", "traffic", "warmup"]),
    Search_menu_item(
      "Queue drain console",
      "#lab-bridge",
      "Replay ownership handoff and worker drain visibility.",
      "queue",
      ["queue", "replay", "worker", "drain"]),
    Search_menu_item(
      "Queue ownership audit",
      "#lab-board",
      "Backpressure notes for cache-safe ownership swaps.",
      "queue",
      ["queue", "ownership", "backpressure", "cache-safe"]),
    Search_menu_item(
      "Image burst monitor",
      "#lab-bridge",
      "Thumbnail worker warmup under burst traffic.",
      "image",
      ["image", "thumbnail", "burst", "warmup"]),
    Search_menu_item(
      "Image variant cache",
      "#lab-board",
      "Derived variant refill and cache tail-latency notes.",
      "image",
      ["image", "variant", "thumbnail", "cache"]),
    Search_menu_item(
      "Dialog overlay drawer",
      "#effects-dialogs",
      "Dismiss bridge, ESC support, and animated drawer exit.",
      "dialog",
      ["dialog", "drawer", "overlay", "escape"]),
    Search_menu_item(
      "Prompt validation flow",
      "#effects-dialogs",
      "Prompt focus effect and validation round-trip.",
      "dialog",
      ["dialog", "prompt", "overlay", "validation"]),
  ]

fun compact_terms(parts : list<string>) : list<string>
  match parts
    Nil -> Nil
    Cons(part, rest) -> if part == "" then compact_terms(rest) else Cons(part, compact_terms(rest))

fun keyword_matches(words : list<string>, target : string) : bool
  match words
    Nil -> False
    Cons(word, rest) -> if word == target then True else keyword_matches(rest, target)

fun query_matches_keywords(terms : list<string>, words : list<string>) : bool
  match terms
    Nil -> False
    Cons(term, rest) -> if keyword_matches(words, term) then True else query_matches_keywords(rest, words)

fun matched_menu_items(items : list<search_menu_item>, query : string) : <div> list<search_menu_item>
  match items
    Nil -> Nil
    Cons(item, rest) -> {
      val next = matched_menu_items(rest, query)
      if search_menu_matches_query(item, query) then Cons(item, next) else next
    }

fun menu_result_line(item : search_menu_item) : string
  search_menu_item/title(item) ++ " -> " ++ search_menu_item/route_hint(item) ++ " | " ++ search_menu_item/note(item)

pub fun search_demo_cases() : list<search_case>
  search_cases()

pub fun search_menu_items() : list<search_menu_item>
  menu_catalog()

pub fun default_search_query() : string
  "edge"

pub fun search_case_by_query(query : string) : <div> maybe<search_case>
  find(search_cases(), fn(item) search_case/query(item) == query)

pub fun search_auto_delay() : int
  240

pub fun search_result_delay(query : string) : <div> int
  match search_case_by_query(query)
    Just(item) -> search_case/result_delay(item)
    Nothing -> 360

pub fun search_timeout_delay(query : string) : <div> int
  match search_case_by_query(query)
    Just(item) -> search_case/timeout_delay(item)
    Nothing -> 340

pub fun search_result_lines(query : string) : <div> list<string>
  match matched_menu_items(menu_catalog(), query)
    Nil -> [
      "No menu item matched `" ++ query ++ "` yet.",
      "Try catalog keywords like `edge`, `queue`, `image`, or `dialog`.",
      "Auto search still uses the same suspense-lite timer and stale-result guards.",
    ]
    items -> map(items, menu_result_line)

pub fun search_case_summary(query : string) : <div> string
  match search_case_by_query(query)
    Just(item) -> search_case/summary(item)
    Nothing -> "Generic query routed through the suspense-lite search demo."

pub fun search_menu_matches_query(item : search_menu_item, query : string) : <div> bool
  query_matches_keywords(compact_terms(split(trim(query), " ")), search_menu_item/keywords(item))

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

pub fun prepare_search_query_update(demo : search_demo, value : string, idle_note : string, armed_note : string, visible_note : string) : <div> (search_demo, bool)
  val trimmed = trim(value)
  val should_arm = should_arm_auto_search(demo, trimmed)
  val next_auto_request_id = if should_arm then demo.auto_request_id + 1 else demo.auto_request_id
  (demo(
    query_input = value,
    auto_status = if should_arm then "armed" else "idle",
    auto_request_id = next_auto_request_id,
    stage_note = if trimmed == "" then idle_note else if should_arm then armed_note else if demo.status == "ready" && trimmed == demo.visible_query then visible_note else demo.stage_note), should_arm)

pub fun prepare_search_start(demo : search_demo, query : string, pending_note : string, refreshing_note : string) : (search_demo, bool)
  val next_request_id = demo.request_id + 1
  val has_visible = demo.visible_query != ""
  (demo(
    query_input = query,
    requested_query = query,
    status = if has_visible then "refreshing" else "pending",
    timeout_status = "pending",
    auto_status = "idle",
    request_id = next_request_id,
    results = if has_visible then demo.results else Nil,
    stage_note = if has_visible then refreshing_note else pending_note), has_visible)

pub fun search_auto_matches(demo : search_demo, query : string, signal_auto_request_id : int) : bool
  demo.auto_status == "armed" && signal_auto_request_id == demo.auto_request_id && query == trim(demo.query_input)

pub fun clear_search_auto(demo : search_demo) : search_demo
  demo(auto_status = "idle")

pub fun search_auto_should_start(demo : search_demo, query : string) : bool
  not(query == demo.requested_query && demo.status != "idle" && demo.status != "timed_out")

pub fun search_request_matches(demo : search_demo, query : string, signal_request_id : int) : bool
  signal_request_id == demo.request_id && query == demo.requested_query

pub fun apply_search_timeout(demo : search_demo, timed_out_note : string, stale_visible_note : string) : maybe<(search_demo, bool)>
  if demo.status == "ready" then
    Nothing
  else {
    val has_visible = demo.visible_query != ""
    Just((demo(
      timeout_status = "timed_out",
      status = if has_visible then "refreshing" else "timed_out",
      stage_note = if has_visible then stale_visible_note else timed_out_note), has_visible))
  }

pub fun apply_search_result(demo : search_demo, query : string, results : list<string>, recovered_note : string, resolved_note : string) : (search_demo, bool)
  val recovered = demo.timeout_status == "timed_out"
  (demo(
    query_input = query,
    visible_query = query,
    status = "ready",
    timeout_status = "idle",
    auto_status = "idle",
    results = results,
    stage_note = if recovered then recovered_note else resolved_note), recovered)

fun search_auto_banner() : vnode
  node_class("div", "search-auto-banner", "bridge-transition-banner search-auto-banner", [
    node_class("div", "search-auto-head", "bridge-transition-head", [
      text_class("strong", "search-auto-title", "bridge-fallback-title", "Typing pause armed an automatic search"),
      text_class("span", "search-auto-status", "incident-status incident-status-investigating", "armed"),
    ]),
    text_class("p", "search-auto-note", "case-detail", "If no newer input arrives, the browser bridge will auto-start the current menu query after the debounce window."),
  ])

fun render_search_result_lines(lines : list<string>) : <div> list<vnode>
  map-indexed(lines, fn(index, line) text_class("li", "search-result-" ++ index.show, "activity-item", line))

fun search_timeout_banner() : vnode
  node_class("div", "search-timeout-banner", "bridge-transition-banner search-timeout-banner", [
    node_class("div", "search-timeout-head", "bridge-transition-head", [
      text_class("strong", "search-timeout-title", "bridge-fallback-title", "Timeout fired before the current result settled"),
      text_class("span", "search-timeout-status", "incident-status incident-severity-p2", "timeout"),
    ]),
    text_class("p", "search-timeout-note", "case-detail", "The current request is late. Suspense-lite keeps stale hits visible when possible and still accepts the same request if it eventually resolves."),
  ])

fun search_transition_banner(demo : search_demo) : <div> vnode
  node_class("div", "search-transition-banner", "bridge-transition-banner", [
    node_class("div", "search-transition-head", "bridge-transition-head", [
      text_class("strong", "search-transition-title", "bridge-fallback-title", "Refreshing search keeps stale hits visible"),
      text_class("span", "search-transition-status", "incident-status incident-status-investigating", "refreshing"),
    ]),
    text_class("p", "search-transition-note", "case-detail", "Showing results for `" ++ demo.visible_query ++ "` while querying `" ++ demo.requested_query ++ "` in the background."),
  ])

pub fun render_search_stage(demo : search_demo, render_fallback : (string, string, string, string) -> <div> vnode) : <div> vnode
  if demo.visible_query == "" && demo.status == "timed_out" then
    render_fallback("search-timeout-fallback", "Search timeout", demo.stage_note, "search-timeout-fallback")
  else if demo.visible_query == "" && demo.status != "ready" then
    render_fallback("search-pending-fallback", "Search fallback", demo.stage_note, "search-pending-fallback")
  else
    node_class("article", "search-result-stage", if demo.status == "refreshing" then "bridge-shell-card search-stage search-stage-refreshing" else "bridge-shell-card search-stage", [
      node_class("div", "search-stage-head", "bridge-shell-head", [
        node_class("div", "search-stage-copy", "stack", [
          text_class("strong", "search-stage-title", "section-title", "Results for `" ++ demo.visible_query ++ "`"),
          text_class("p", "search-stage-note", "case-detail", demo.stage_note),
        ]),
        node_class("div", "search-stage-badges", "bridge-shell-badges", [
          text_class("span", "search-stage-status", "incident-status incident-status-investigating", demo.status),
        ]),
      ]),
      if demo.status == "refreshing" then search_transition_banner(demo) else node_class("div", "search-transition-placeholder", "stack", Nil),
      if demo.auto_status == "armed" then search_auto_banner() else node_class("div", "search-auto-placeholder", "stack", Nil),
      if demo.timeout_status == "timed_out" then search_timeout_banner() else node_class("div", "search-timeout-placeholder", "stack", Nil),
      node_class("ul", "search-results", "activity-list", render_search_result_lines(demo.results)),
    ])