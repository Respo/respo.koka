module demo/lab/view

import demo/model
import demo/lab/events
import demo/shared
import demo/lab/state
import respo/core
import respo/state

alias lab_view_effect = <push_hook_scope,pop_hook_scope,use_state,register_listener<model,browser_event_effect>,div>

fun severity_class(item : incident) : string
  if incident_severity(item) == "p1" then "incident-severity incident-severity-p1"
  else if incident_severity(item) == "p2" then "incident-severity incident-severity-p2"
  else "incident-severity incident-severity-p3"

fun status_class(item : incident) : string
  if incident_status(item) == "acked" then "incident-status incident-status-acked"
  else if incident_status(item) == "investigating" then "incident-status incident-status-investigating"
  else "incident-status incident-status-firing"

fun incident_card(item : incident) : lab_view_effect vnode
  component(incident_hook_scope(incident_id(item)), fn() {
    val item_scope = incident_hook_scope(incident_id(item))
    val expanded = use_state(flag_state_codec, False)
    val draft = use_state(text_state_codec, "")
    val toggle_label = if expanded then "Collapse" else "Expand"
    val preview_text = if draft == "" then "local draft: <empty>" else "local draft: " ++ draft
    val collapsed_text = if draft == "" then "Draft is local and still empty." else "Draft saved locally for this card."
    val detail_node = if expanded then
      node_class("div", "incident-detail-" ++ incident_id(item).show, "incident-detail-grid", [
        text_class("p", "incident-remote-" ++ incident_id(item).show, "mono", "server: " ++ incident_server_note(item)),
        text_class("p", "incident-owner-" ++ incident_id(item).show, "mono", "updated by: " ++ incident_updated_by(item)),
        text_class("p", "incident-draft-preview-" ++ incident_id(item).show, "mono", preview_text),
      ])
    else
      text_class("p", "incident-collapsed-" ++ incident_id(item).show, "mono", collapsed_text)
    node_class("article", "incident-" ++ incident_id(item).show, "incident-card", [
      node_class("div", "incident-head-" ++ incident_id(item).show, "incident-head", [
        node_class("div", "incident-title-wrap-" ++ incident_id(item).show, "incident-title-wrap", [
          text_class("strong", "incident-title-" ++ incident_id(item).show, "incident-title", incident_title(item)),
          text_class("span", "incident-summary-" ++ incident_id(item).show, "case-detail", incident_summary(item)),
        ]),
        node_class("div", "incident-badges-" ++ incident_id(item).show, "incident-badges", [
          text_class("span", "incident-severity-" ++ incident_id(item).show, severity_class(item), incident_severity(item)),
          text_class("span", "incident-status-" ++ incident_id(item).show, status_class(item), incident_status(item)),
        ]),
      ]),
      node_class("div", "incident-controls-" ++ incident_id(item).show, "incident-controls", [
        button_class(incident_toggle_payload(item), "button", [on_named_click(item_scope, "toggle-expanded", fn(owner) commit_lab_tree(owner, fn() toggle_local_lab_expanded(owner, incident_id(item))))], toggle_label),
        text_input(incident_draft_channel(item), "input incident-input", draft, "Local reply draft, per card...", Nil, [
          on_named_input(item_scope, "draft-input", fn(value, owner) commit_lab_tree(owner, fn() set_local_lab_draft(owner, incident_id(item), value))),
          dispatch_lab_enter(Send_reply(incident_id(item))),
        ]),
        button_class(incident_send_payload(item), "button button-primary", [dispatch_lab_click(Send_reply(incident_id(item)))], "Send reply"),
      ]),
      detail_node,
    ])
  })

fun render_incident_cards(items : list<incident>) : lab_view_effect list<vnode>
  map(items, incident_card)

fun incident_grid(lab : workflow_lab) : lab_view_effect vnode
  node_class("div", "incident-grid", "incident-grid", render_incident_cards(lab_incidents(lab)))

fun render_activity_items(lines : list<string>) : <div> list<vnode>
  map-indexed(lines, fn(index, line) text_class("li", "activity-" ++ index.show, "activity-item", line))

fun activity_panel(lab : workflow_lab) : <div> vnode
  node_class("aside", "lab-activity", "mini-panel activity-panel", [
    text_node("strong", "lab-activity-title", empty_props, "Workflow activity"),
    text_class("p", "lab-activity-note", "case-detail", "Each sync or reply appends a line that can be asserted in tests."),
    node_class("ul", "lab-activity-list", "activity-list", render_activity_items(lab_activity_log(lab))),
  ])

pub fun render_lab_panel(item : model) : lab_view_effect vnode
  val lab = model_lab(item)
  panel("Workflow lab", "This demo mixes component-local draft state, staged waits, a mocked server snapshot, and an ambient operator identity.", "lab", "lab-panel", [
    node_class("div", "lab-summary", "summary-row", [
      summary_chip("Incidents", lab_incident_count(lab).show),
      summary_chip("Open", lab_open_count(lab).show),
      summary_chip("Drafts", lab_draft_count(lab).show),
      summary_chip("Local cells", lab_local_count(lab).show),
      summary_chip("Last sync", lab_last_sync_label(lab)),
    ]),
    node_class("div", "lab-actions", "button-row", [
      button_class("lab-load", "button", [dispatch_lab_click(Load_board)], "Load mock board"),
      button_class("lab-sync", "button button-primary", [dispatch_lab_click(Run_sync)], "Run staged sync"),
      text_class("span", "lab-status", "mono", "status: " ++ lab_sync_status(lab)),
    ]),
    node_class("div", "lab-body", "lab-body-grid", [
      incident_grid(lab),
      activity_panel(lab),
    ]),
  ])
