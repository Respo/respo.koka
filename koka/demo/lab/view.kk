module demo/lab/view

import demo/model
import demo/lab/events
import demo/shared
import demo/lab/state
import respo/core
import respo/state

alias lab_view_effect = <push_hook_scope,pop_hook_scope,use_state,on_click<model,browser_event_effect>,on_input<model>,on_enter<model,browser_event_effect>,div>

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
      el("div", "incident-detail-" ++ incident_id(item).show, [class_attr("incident-detail-grid")], Nil, "", [
        el("p", "incident-remote-" ++ incident_id(item).show, [class_attr("mono")], Nil, "server: " ++ incident_server_note(item), Nil),
        el("p", "incident-owner-" ++ incident_id(item).show, [class_attr("mono")], Nil, "updated by: " ++ incident_updated_by(item), Nil),
        el("p", "incident-draft-preview-" ++ incident_id(item).show, [class_attr("mono")], Nil, preview_text, Nil),
      ])
    else
      el("p", "incident-collapsed-" ++ incident_id(item).show, [class_attr("mono")], Nil, collapsed_text, Nil)
    el("article", "incident-" ++ incident_id(item).show, [class_attr("incident-card")], Nil, "", [
      el("div", "incident-head-" ++ incident_id(item).show, [class_attr("incident-head")], Nil, "", [
        el("div", "incident-title-wrap-" ++ incident_id(item).show, [class_attr("incident-title-wrap")], Nil, "", [
          el("strong", "incident-title-" ++ incident_id(item).show, [class_attr("incident-title")], Nil, incident_title(item), Nil),
          el("span", "incident-summary-" ++ incident_id(item).show, [class_attr("case-detail")], Nil, incident_summary(item), Nil),
        ]),
        el("div", "incident-badges-" ++ incident_id(item).show, [class_attr("incident-badges")], Nil, "", [
          el("span", "incident-severity-" ++ incident_id(item).show, [class_attr(severity_class(item))], Nil, incident_severity(item), Nil),
          el("span", "incident-status-" ++ incident_id(item).show, [class_attr(status_class(item))], Nil, incident_status(item), Nil),
        ]),
      ]),
      el("div", "incident-controls-" ++ incident_id(item).show, [class_attr("incident-controls")], Nil, "", [
        el("button", incident_toggle_payload(item), [class_attr("button")], [on_named_click(item_scope, "toggle-expanded", fn(owner) commit_lab_tree(owner, fn() toggle_local_lab_expanded(owner, incident_id(item))))], toggle_label, Nil),
        el("input", incident_draft_channel(item), [class_attr("input incident-input"), text_attr("type", "text"), text_attr("value", draft), text_attr("placeholder", "Local reply draft, per card...")], [on_named_input(item_scope, "draft-input", fn(value, owner) commit_lab_tree(owner, fn() set_local_lab_draft(owner, incident_id(item), value))), dispatch_lab_enter(Send_reply(incident_id(item)))], "", Nil),
        el("button", incident_send_payload(item), [class_attr("button button-primary")], [dispatch_lab_click(Send_reply(incident_id(item)))], "Send reply", Nil),
      ]),
      detail_node,
    ])
  })

fun render_incident_cards(items : list<incident>) : lab_view_effect list<vnode>
  match items
    Nil -> Nil
    Cons(item, rest) -> Cons(incident_card(item), render_incident_cards(rest))

fun incident_grid(lab : workflow_lab) : lab_view_effect vnode
  el("div", "incident-grid", [class_attr("incident-grid")], Nil, "", render_incident_cards(lab_incidents(lab)))

fun render_activity_items(lines : list<string>, index : int) : <div> list<vnode>
  match lines
    Nil -> Nil
    Cons(line, rest) -> Cons(el("li", "activity-" ++ index.show, [class_attr("activity-item")], Nil, line, Nil), render_activity_items(rest, index + 1))

fun activity_panel(lab : workflow_lab) : <div> vnode
  el("aside", "lab-activity", [class_attr("mini-panel activity-panel")], Nil, "", [
    el("strong", "lab-activity-title", Nil, Nil, "Workflow activity", Nil),
    el("p", "lab-activity-note", [class_attr("case-detail")], Nil, "Each sync or reply appends a line that can be asserted in tests.", Nil),
    el("ul", "lab-activity-list", [class_attr("activity-list")], Nil, "", render_activity_items(lab_activity_log(lab), 0)),
  ])

pub fun render_lab_panel(item : model) : lab_view_effect vnode
  val lab = model_lab(item)
  panel("Workflow lab", "This demo mixes component-local draft state, staged waits, a mocked server snapshot, and an ambient operator identity.", "lab", "lab-panel", [
    el("div", "lab-summary", [class_attr("summary-row")], Nil, "", [
      summary_chip("Incidents", lab_incident_count(lab).show),
      summary_chip("Open", lab_open_count(lab).show),
      summary_chip("Drafts", lab_draft_count(lab).show),
      summary_chip("Local cells", lab_local_count(lab).show),
      summary_chip("Last sync", lab_last_sync_label(lab)),
    ]),
    el("div", "lab-actions", [class_attr("button-row")], Nil, "", [
      el("button", "lab-load", [class_attr("button")], [dispatch_lab_click(Load_board)], "Load mock board", Nil),
      el("button", "lab-sync", [class_attr("button button-primary")], [dispatch_lab_click(Run_sync)], "Run staged sync", Nil),
      el("span", "lab-status", [class_attr("mono")], Nil, "status: " ++ lab_sync_status(lab), Nil),
    ]),
    el("div", "lab-body", [class_attr("lab-body-grid")], Nil, "", [
      incident_grid(lab),
      activity_panel(lab),
    ]),
  ])