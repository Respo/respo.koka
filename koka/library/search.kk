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

fun search_case_button(item : search_case, requested_query : string, visible_query : string, dispatch_search : string -> listener) : <div> vnode
  val query = search_case/query(item)
  val class_name =
    if query == visible_query then "button button-active"
    else if query == requested_query then "button button-primary bridge-button-pending"
    else "button"
  button([class_attr(class_name)], [dispatch_search(query)], search_case/label(item))

pub fun render_search_case_buttons(items : list<search_case>, requested_query : string, visible_query : string, dispatch_search : string -> listener) : <div> list<vnode>
  map(items, fn(item) search_case_button(item, requested_query, visible_query, dispatch_search))

fun render_menu_keyword_pills(items : list<string>, key_prefix : string) : <div> list<vnode>
  map-indexed(items, fn(index, item) span_key(key_prefix ++ "-keyword-" ++ index.show, [class_attr("search-keyword-chip")], item))

fun search_menu_card(item : search_menu_item, query : string, dispatch_search : string -> listener) : <div> vnode
  val is_match = search_menu_matches_query(item, query)
  val button_class_name = if query == search_menu_item/query_hint(item) then "button button-active" else if is_match then "button button-primary" else "button"
  article([class_attr(if is_match then "search-menu-card search-menu-card-match" else "search-menu-card")], [
    div([class_attr("search-menu-head")], [
      div([class_attr("stack")], [
        strong([class_attr("section-title")], search_menu_item/title(item)),
        p([class_attr("mono")], search_menu_item/route_hint(item)),
      ]),
      button([class_attr(button_class_name)], [dispatch_search(search_menu_item/query_hint(item))], "Search " ++ search_menu_item/query_hint(item)),
    ]),
    p([class_attr("case-detail")], search_menu_item/note(item)),
    div([class_attr("search-menu-keywords")], render_menu_keyword_pills(search_menu_item/keywords(item), search_menu_item/query_hint(item))),
  ])

pub fun render_search_menu(items : list<search_menu_item>, query : string, dispatch_search : string -> listener) : <div> list<vnode>
  map(items, fn(item) search_menu_card(item, query, dispatch_search))

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
  div([class_attr("bridge-transition-banner search-auto-banner")], [
    div([class_attr("bridge-transition-head")], [
      strong([class_attr("bridge-fallback-title")], "Typing pause armed an automatic search"),
      span([class_attr("incident-status incident-status-investigating")], "armed"),
    ]),
    p([class_attr("case-detail")], "If no newer input arrives, the browser bridge will auto-start the current menu query after the debounce window."),
  ])

fun render_search_result_lines(lines : list<string>) : <div> list<vnode>
  map-indexed(lines, fn(index, line) li_text_key("search-result-" ++ index.show, [class_attr("activity-item")], line))

fun search_timeout_banner() : vnode
  div([class_attr("bridge-transition-banner search-timeout-banner")], [
    div([class_attr("bridge-transition-head")], [
      strong([class_attr("bridge-fallback-title")], "Timeout fired before the current result settled"),
      span([class_attr("incident-status incident-severity-p2")], "timeout"),
    ]),
    p([class_attr("case-detail")], "The current request is late. Suspense-lite keeps stale hits visible when possible and still accepts the same request if it eventually resolves."),
  ])

fun search_transition_banner(demo : search_demo) : <div> vnode
  div([class_attr("bridge-transition-banner")], [
    div([class_attr("bridge-transition-head")], [
      strong([class_attr("bridge-fallback-title")], "Refreshing search keeps stale hits visible"),
      span([class_attr("incident-status incident-status-investigating")], "refreshing"),
    ]),
    p([class_attr("case-detail")], "Showing results for `" ++ demo.visible_query ++ "` while querying `" ++ demo.requested_query ++ "` in the background."),
  ])

pub fun render_search_stage(demo : search_demo, render_fallback : (string, string, string, string) -> <div> vnode) : <div> vnode
  if demo.visible_query == "" && demo.status == "timed_out" then
    render_fallback("search-timeout-fallback", "Search timeout", demo.stage_note, "search-timeout-fallback")
  else if demo.visible_query == "" && demo.status != "ready" then
    render_fallback("search-pending-fallback", "Search fallback", demo.stage_note, "search-pending-fallback")
  else
    article([class_attr(if demo.status == "refreshing" then "bridge-shell-card search-stage search-stage-refreshing" else "bridge-shell-card search-stage")], [
      div([class_attr("bridge-shell-head")], [
        div([class_attr("stack")], [
          strong([class_attr("section-title")], "Results for `" ++ demo.visible_query ++ "`"),
          p([class_attr("case-detail")], demo.stage_note),
        ]),
        div([class_attr("bridge-shell-badges")], [
          span([class_attr("incident-status incident-status-investigating")], demo.status),
        ]),
      ]),
      if demo.status == "refreshing" then search_transition_banner(demo) else div([class_attr("stack")], Nil),
      if demo.auto_status == "armed" then search_auto_banner() else div([class_attr("stack")], Nil),
      if demo.timeout_status == "timed_out" then search_timeout_banner() else div([class_attr("stack")], Nil),
      ul([class_attr("activity-list")], render_search_result_lines(demo.results)),
    ])

pub fun render_search_panel(demo : search_demo, render_summary_chip : (string, string) -> vnode, dispatch_submit : listener, dispatch_search : string -> listener, render_fallback : (string, string, string, string) -> <div> vnode) : <div> vnode
  val current_query = if trim(demo.query_input) == "" then demo.visible_query else trim(demo.query_input)
  section_key("lab-search", [class_attr("bridge-panel search-panel")], [
    div([class_attr("bridge-panel-head")], [
      div([class_attr("stack")], [
        strong([class_attr("section-title")], "Suspense-lite search demo"),
        p([class_attr("case-detail")], "User input stays interactive while a debounced auto-search, mocked server results, and timeout callbacks race through the bridge layer against a menu catalog."),
      ]),
      div([class_attr("summary-row bridge-meta")], [
        render_summary_chip("Requested", if demo.requested_query == "" then "<none>" else demo.requested_query),
        render_summary_chip("Visible", if demo.visible_query == "" then "<fallback>" else demo.visible_query),
        render_summary_chip("Status", demo.status),
        render_summary_chip("Timeout", demo.timeout_status),
        render_summary_chip("Auto", demo.auto_status),
      ]),
    ]),
    div([class_attr("composer-row")], [
      input_text_key(search_query_channel(), [class_attr("input")], [input_listener(search_query_channel()), dispatch_submit], demo.query_input, "Pause on `edge`, `queue`, `image`, `dialog` ..."),
      button([class_attr("button button-primary")], [dispatch_submit], "Run search"),
      span([class_attr("mono")], "request #" ++ demo.request_id.show ++ " / auto #" ++ demo.auto_request_id.show),
    ]),
    div([class_attr("button-row bridge-case-row")], render_search_case_buttons(search_demo_cases(), demo.requested_query, demo.visible_query, dispatch_search)),
    div([class_attr("search-menu-grid")], render_search_menu(search_menu_items(), current_query, dispatch_search)),
    render_search_stage(demo, render_fallback),
  ])