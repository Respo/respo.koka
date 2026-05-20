module library/bridge

import respo/core

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

pub fun bridge_demo_cases() : list<bridge_case>
  suspense_cases()

pub fun default_bridge_case_name() : string
  "edge-auth"

pub fun bridge_case_by_name(case_name : string) : <div> maybe<bridge_case>
  find(suspense_cases(), fn(item) bridge_case/name(item) == case_name)

pub fun bridge_shell_delay(case_name : string) : <div> int
  match bridge_case_by_name(case_name)
    Just(item) -> bridge_case/shell_delay(item)
    Nothing -> 600

pub fun bridge_detail_delay(case_name : string) : <div> int
  match bridge_case_by_name(case_name)
    Just(item) -> bridge_case/detail_delay(item)
    Nothing -> 900

pub fun render_bridge_fallback(key : string, title : string, note : string, class_name : string) : <div> vnode
  node_class("div", key, "bridge-fallback " ++ class_name, [
    text_class("strong", key ++ "-title", "bridge-fallback-title", title),
    text_class("p", key ++ "-note", "case-detail", note),
    node_class("div", key ++ "-bars", "bridge-fallback-bars", [
      node_class("span", key ++ "-bar-1", "bridge-bar bridge-bar-wide", Nil),
      node_class("span", key ++ "-bar-2", "bridge-bar bridge-bar-mid", Nil),
      node_class("span", key ++ "-bar-3", "bridge-bar bridge-bar-short", Nil),
    ]),
  ])

fun bridge_case_button(item : bridge_case, requested_case : string, visible_case : string, dispatch_case : string -> listener) : <div> vnode
  val case_name = bridge_case/name(item)
  val class_name =
    if case_name == visible_case then "button button-active"
    else if case_name == requested_case then "button button-primary bridge-button-pending"
    else "button"
  button_class("bridge-case-" ++ case_name, class_name, [dispatch_case(case_name)], bridge_case/label(item))

pub fun render_bridge_case_buttons(items : list<bridge_case>, requested_case : string, visible_case : string, dispatch_case : string -> listener) : <div> list<vnode>
  map(items, fn(item) bridge_case_button(item, requested_case, visible_case, dispatch_case))

fun render_bridge_detail_lines(lines : list<string>) : <div> list<vnode>
  map-indexed(lines, fn(index, line) text_class("li", "bridge-detail-" ++ index.show, "activity-item", line))

fun bridge_transition_banner(requested_case : string, visible_case : string) : vnode
  node_class("div", "bridge-transition-banner", "bridge-transition-banner", [
    node_class("div", "bridge-transition-head", "bridge-transition-head", [
      text_class("strong", "bridge-transition-title", "bridge-fallback-title", "Transition keeps stale content visible"),
      text_class("span", "bridge-transition-status", "incident-status incident-status-investigating", "refreshing"),
    ]),
    text_class("p", "bridge-transition-note", "case-detail", "Currently showing `" ++ visible_case ++ "` while the browser bridge resolves `" ++ requested_case ++ "` in the background."),
    node_class("div", "bridge-transition-rail", "bridge-transition-rail", [
      text_class("span", "bridge-visible-token", "bridge-token bridge-token-current", "visible: " ++ visible_case),
      text_class("span", "bridge-arrow-token", "bridge-arrow-token", "->"),
      text_class("span", "bridge-requested-token", "bridge-token bridge-token-next", "next: " ++ requested_case),
    ]),
  ])

fun bridge_detail_node(case_item : bridge_case, detail_status : string) : <div> vnode
  if detail_status == "ready" then
    node_class("div", "bridge-detail", "bridge-detail-card", [
      text_class("strong", "bridge-detail-title", "section-title", bridge_case/detail_title(case_item)),
      text_class("p", "bridge-detail-note", "case-detail", "Nested boundary resolved after the outer shell became visible."),
      node_class("ul", "bridge-detail-list", "activity-list", render_bridge_detail_lines(bridge_case/detail_lines(case_item))),
    ])
  else
    render_bridge_fallback("bridge-detail-fallback", "Nested fallback", "Shell is visible, but the diagnostic trace is still suspended through the browser callback bridge.", "bridge-detail-fallback")

fun bridge_shell_node(case_item : bridge_case, requested_case : string, visible_case : string, shell_status : string, detail_status : string) : <div> vnode
  val is_refreshing = shell_status == "refreshing"
  val shell_class = if is_refreshing then "bridge-shell-card bridge-shell-refreshing" else "bridge-shell-card"
  val status_text = if is_refreshing then "showing stale shell while requesting `" ++ requested_case ++ "`" else "outer boundary resolved"
  val body_children = if is_refreshing then
    [
      node_class("div", "bridge-shell-head", "bridge-shell-head", [
        node_class("div", "bridge-shell-copy", "stack", [
          text_class("strong", "bridge-shell-title", "section-title", bridge_case/shell_title(case_item)),
          text_class("p", "bridge-shell-summary", "case-detail", bridge_case/shell_summary(case_item)),
        ]),
        node_class("div", "bridge-shell-badges", "bridge-shell-badges", [
          text_class("span", "bridge-shell-status", "incident-status incident-status-investigating", status_text),
        ]),
      ]),
      bridge_transition_banner(requested_case, visible_case),
      text_class("p", "bridge-shell-stage-note", "bridge-state-note", bridge_case/stage_note(case_item)),
      bridge_detail_node(case_item, detail_status),
    ]
  else
    [
      node_class("div", "bridge-shell-head", "bridge-shell-head", [
        node_class("div", "bridge-shell-copy", "stack", [
          text_class("strong", "bridge-shell-title", "section-title", bridge_case/shell_title(case_item)),
          text_class("p", "bridge-shell-summary", "case-detail", bridge_case/shell_summary(case_item)),
        ]),
        node_class("div", "bridge-shell-badges", "bridge-shell-badges", [
          text_class("span", "bridge-shell-status", "incident-status incident-status-investigating", status_text),
        ]),
      ]),
      text_class("p", "bridge-shell-stage-note", "bridge-state-note", bridge_case/stage_note(case_item)),
      bridge_detail_node(case_item, detail_status),
    ]
  node_class("article", "bridge-shell", shell_class, body_children)

pub fun render_bridge_stage(selected_case : maybe<bridge_case>, requested_note : string, requested_case : string, visible_case : string, shell_status : string, detail_status : string) : <div> vnode
  match selected_case
    Just(case_item) -> if visible_case == "" && shell_status != "ready" then
      render_bridge_fallback("bridge-shell-fallback", "Outer fallback", requested_note, "bridge-shell-fallback")
    else
      bridge_shell_node(case_item, requested_case, visible_case, shell_status, detail_status)
    Nothing -> node_class("div", "bridge-empty", "bridge-empty", [
      text_class("strong", "bridge-empty-title", "section-title", "Suspense-like bridge demo"),
      text_class("p", "bridge-empty-note", "case-detail", "Select a case to trigger a browser callback that resolves the shell and nested diagnostics in two stages."),
    ])