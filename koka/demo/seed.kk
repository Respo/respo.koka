module demo/seed

import demo/model

pub struct bridge_case
  name : string
  label : string
  stage_note : string
  shell_title : string
  shell_summary : string
  detail_title : string
  detail_lines : list<string>
  shell_delay : int
  detail_delay : int

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

fun suspense_cases() : list<bridge_case>
  [
    Bridge_case(
      "edge-auth",
      "Edge Auth Bundle",
      "Outer boundary keeps the last visible incident brief while the browser callback resolves a newer auth snapshot.",
      "Auth bundle drift at the edge",
      "Two POPs are still serving an older login shell, so the demo keeps stale content on screen until the replacement shell lands.",
      "Nested diagnostics stream",
      [
        "cdn.trace: auth-shell-v42 is still hot in iad / hkg",
        "origin.diff: manifest hash moved from 7fd2 to 91ac",
        "mitigation: warm the new shell before swapping visible traffic",
      ],
      520,
      980),
    Bridge_case(
      "queue-drain",
      "Replay Queue Drain",
      "This case shows a slower outer shell and a faster nested payload once the queue owner flips.",
      "Replay queue ownership handoff",
      "The staging queue is rebalancing across workers, so the demo waits longer before revealing the next operator view.",
      "Queue replay trace",
      [
        "ingress: backlog crest detected after deploy wave 19",
        "scheduler: ownership moved to cache-safe workers",
        "replay: pressure drops only after the nested trace resolves",
      ],
      820,
      540),
    Bridge_case(
      "image-burst",
      "Thumbnail Burst",
      "The shell swaps quickly, but the nested diagnostics intentionally linger to mimic a second Suspense boundary.",
      "Thumbnail region warmup burst",
      "A new region is ready to reveal high-level status, while the per-stage trace keeps streaming under a nested fallback.",
      "Worker warmup detail",
      [
        "loader: region enters warm path after first request batch",
        "cache: derived variants refill after the shell is already visible",
        "tail-latency: final p95 settles only when nested detail completes",
      ],
      360,
      1180),
  ]

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
      "/lab/bridge/edge-auth",
      "Staged shell/detail bridge around auth drift at the edge POPs.",
      "edge",
      ["edge", "auth", "cache", "login"]),
    Search_menu_item(
      "Edge rollout timeline",
      "/lab/bridge/image-burst",
      "Transition timeline for warmup, rollout, and stale-shell recovery.",
      "edge",
      ["edge", "rollout", "traffic", "warmup"]),
    Search_menu_item(
      "Queue drain console",
      "/lab/bridge/queue-drain",
      "Replay ownership handoff and worker drain visibility.",
      "queue",
      ["queue", "replay", "worker", "drain"]),
    Search_menu_item(
      "Queue ownership audit",
      "/lab/workflow/replies",
      "Backpressure notes for cache-safe ownership swaps.",
      "queue",
      ["queue", "ownership", "backpressure", "cache-safe"]),
    Search_menu_item(
      "Image burst monitor",
      "/lab/bridge/image-burst",
      "Thumbnail worker warmup under burst traffic.",
      "image",
      ["image", "thumbnail", "burst", "warmup"]),
    Search_menu_item(
      "Image variant cache",
      "/lab/workflow/cache",
      "Derived variant refill and cache tail-latency notes.",
      "image",
      ["image", "variant", "thumbnail", "cache"]),
    Search_menu_item(
      "Dialog overlay drawer",
      "/effects/dialogs/drawer",
      "Dismiss bridge, ESC support, and animated drawer exit.",
      "dialog",
      ["dialog", "drawer", "overlay", "escape"]),
    Search_menu_item(
      "Prompt validation flow",
      "/effects/dialogs/prompt",
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

pub fun bridge_demo_cases() : list<bridge_case>
  suspense_cases()

pub fun default_bridge_case_name() : string
  "edge-auth"

pub fun search_demo_cases() : list<search_case>
  search_cases()

pub fun search_menu_items() : list<search_menu_item>
  menu_catalog()

pub fun default_search_query() : string
  "edge"

pub fun bridge_case_by_name(case_name : string) : <div> maybe<bridge_case>
  find(suspense_cases(), fn(item) bridge_case/name(item) == case_name)

pub fun search_case_by_query(query : string) : <div> maybe<search_case>
  find(search_cases(), fn(item) search_case/query(item) == query)

pub fun search_auto_delay() : int
  240

pub fun bridge_shell_delay(case_name : string) : <div> int
  match bridge_case_by_name(case_name)
    Just(item) -> bridge_case/shell_delay(item)
    Nothing -> 600

pub fun bridge_detail_delay(case_name : string) : <div> int
  match bridge_case_by_name(case_name)
    Just(item) -> bridge_case/detail_delay(item)
    Nothing -> 900

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

pub fun mock_lab_snapshot() : lab_snapshot
  Lab_snapshot(
    [
      Incident(101, "Edge cache serving stale auth bundle", "p1", "firing", "Login JS bundle is 17 minutes behind origin in two POPs.", "Origin checksum mismatch observed on 4 probes.", "mock-edge-bot"),
      Incident(102, "Worker queue saturation", "p2", "investigating", "Batch replay queue is at 86% depth after the latest deploy.", "Autoscaler added one node but backlog is still trending up.", "ops-sim"),
      Incident(103, "Image thumbnail cold start", "p3", "acked", "New region takes 1.3s to warm the thumbnail worker.", "Tracked for the next runtime image cut.", "ops-sim"),
    ],
    "Mock server returned 3 incidents for the workflow lab.")

pub fun mock_lab_reply(incident_id : int, message : string) : string
  "Mock server accepted reply for #" ++ incident_id.show ++ ": " ++ message

fun initial_lab() : workflow_lab
  Workflow_lab(
    lab_snapshot_incidents(mock_lab_snapshot()),
    ["[boot] Seeded workflow lab with a deterministic snapshot."],
    Nil,
    "seeded",
    "boot",
    initial_bridge_demo(default_bridge_case_name()),
    initial_search_demo(default_search_query()))

pub fun initial_model() : model
  Model(
    [
      Task(1, "Map React-like updates onto a Koka store", True),
      Task(2, "Keep diff + patch inside Koka", False),
      Task(3, "Use algebraic effects for destructive flows", False),
    ],
    "",
    4,
    "all",
    "Ready: Koka owns components, state, and diff/patch.",
    "overview",
    Nil,
    initial_lab(),
    initial_dialog_demo())