module demo/seed

import demo/model

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
    "boot")

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