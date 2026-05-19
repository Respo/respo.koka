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
    initial_bridge_demo(default_bridge_case_name()))

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
    initial_lab())