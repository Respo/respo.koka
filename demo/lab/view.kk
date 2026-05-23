module demo/lab/view

import demo/model
import demo/lab/events
import demo/lab/search
import demo/shared
import demo/lab/state
import library/bridge
import library/search
import respo/core
import respo/state

alias lab_view_effect = <current_hook_scope_name,push_hook_scope,pop_hook_scope,lab_local_effect,register_listener<model,browser_event_effect>>

fun severity_class(item : incident) : string
  match item.severity
    Severity_p1 -> "incident-severity incident-severity-p1"
    Severity_p2 -> "incident-severity incident-severity-p2"
    Severity_p3 -> "incident-severity incident-severity-p3"

fun status_class(item : incident) : string
  match item.status
    Status_acked -> "incident-status incident-status-acked"
    Status_investigating -> "incident-status incident-status-investigating"
    Status_firing -> "incident-status incident-status-firing"

fun incident_card(item : incident) : lab_view_effect vnode
  val iid = incident/id(item)
  val (expanded, _set_expanded) = use_state_pair(flag_state_codec, False)
  val (draft, _set_draft) = use_state_pair(text_state_codec, "")
  val toggle_label = if expanded then "Collapse" else "Expand"
  val preview_text = if draft == "" then "local draft: <empty>" else "local draft: " ++ draft
  val collapsed_text = if draft == "" then "Draft is local and still empty." else "Draft saved locally for this card."
  val detail_node = if expanded then
    div([class_attr("incident-detail-grid")], [
      p([class_attr("mono")], "server: " ++ item.server_note),
      p([class_attr("mono")], "updated by: " ++ item.updated_by),
      p([class_attr("mono")], preview_text),
    ])
  else
    p([class_attr("mono")], collapsed_text)
  article_key("incident-" ++ iid.show, [class_attr("incident-card")], [
    div([class_attr("incident-head")], [
      div([class_attr("incident-title-wrap")], [
        strong([class_attr("incident-title")], item.title),
        span([class_attr("case-detail")], item.summary),
      ]),
      div([class_attr("incident-badges")], [
        span([class_attr(severity_class(item))], item.severity.show_severity),
        span([class_attr(status_class(item))], item.status.show_status),
      ]),
    ]),
    div([class_attr("incident-controls")], [
      button([class_attr("button")], [on_local_click("toggle-expanded", fn(owner : model) commit_lab_tree(owner, fn() toggle_local_lab_expanded(owner, iid)))], toggle_label),
      input_text_key("lab-draft-" ++ iid.show, [class_attr("input incident-input")], [
        on_local_input("draft-input", fn(value, owner : model) commit_lab_tree(owner, fn() set_local_lab_draft(owner, iid, value))),
        on_local_enter("send-reply", fn(owner : model) dispatch_lab_action(Send_reply(iid), owner)),
      ], draft, "Local reply draft, per card..."),
      button([class_attr("button button-primary")], [on_local_click("send-reply", fn(m : model) dispatch_lab_action(Send_reply(iid), m))], "Send reply"),
    ]),
    detail_node,
  ])

fun render_incident_cards(items : list<incident>) : lab_view_effect list<vnode>
  map(items, fn(item) component_in("incidents", incident/id(item).show, fn() incident_card(item)))

fun incident_grid(lab : workflow_lab) : lab_view_effect vnode
  div([class_attr("incident-grid")], render_incident_cards(lab.incidents))

fun render_activity_items(lines : list<string>) : <div> list<vnode>
  map-indexed(lines, fn(index, line) li_text_key("activity-" ++ index.show, [class_attr("activity-item")], line))

fun activity_panel(lab : workflow_lab) : <div> vnode
  aside([class_attr("mini-panel activity-panel")], [
    strong(Nil, "Workflow activity"),
    p([class_attr("case-detail")], "Each sync or reply appends a line that can be asserted in tests."),
    ul([class_attr("activity-list")], render_activity_items(lab.activity_log)),
  ])

fun lab_panel_note(route_name : string) : string
  if route_name == "lab-search" then "Search is isolated here so debounced auto-run, timeout racing, stale-result retention, and the menu catalog are easier to inspect by themselves."
  else if route_name == "lab-bridge" then "Bridge is isolated here so the staged shell/detail suspense-like behavior is not competing with the workflow board or search demo."
  else "Board keeps the incident workflow, local drafts, activity log, and staged sync actions together without the search and bridge demos crowding the same page."

fun lab_panel_sections(route_name : string, lab : workflow_lab) : lab_view_effect list<vnode>
  if route_name == "lab-search" then {
    val submit_listener = on_local_enter("submit-search", fn(m : model) dispatch_lab_action(Submit_search, m))
    [render_search_panel(lab.search_demo, submit_listener, fn(query) dispatch_lab_click(Search_for(query)))]
  }
  else if route_name == "lab-bridge" then
    [render_bridge_panel(lab.bridge_demo, summary_chip, fn(case_name) dispatch_lab_click(Load_bridge_case(case_name)))]
  else
    [
      div([class_attr("button-row")], [
        button([class_attr("button")], [on_local_click("load-board", fn(m : model) dispatch_lab_action(Load_board, m))], "Load mock board"),
        button([class_attr("button button-primary")], [on_local_click("run-sync", fn(m : model) dispatch_lab_action(Run_sync, m))], "Run staged sync"),
        span([class_attr("mono")], "status: " ++ lab.sync_status),
      ]),
      div([class_attr("lab-body-grid")], [
        incident_grid(lab),
        activity_panel(lab),
      ]),
    ]

pub fun render_lab_panel(item : model) : lab_view_effect vnode
  val lab = item.lab
  val children = [
    div([class_attr("summary-row")], [
      summary_chip("Incidents", length(lab.incidents).show),
      summary_chip("Open", length(filter(lab.incidents, fn(incident_item) match incident_item.status { Status_acked -> False; _ -> True })).show),
      summary_chip("Drafts", length(filter(lab.incidents, fn(incident_item) lab_incident_draft(item.app_local_tree, incident/id(incident_item)) != "")).show),
      summary_chip("Local cells", count_entries(item.app_local_tree).show),
      summary_chip("Last sync", lab.last_sync_label),
    ]),
  ] ++ lab_panel_sections(item.route_name, lab)
  panel("Workflow lab", lab_panel_note(item.route_name), "lab", "lab-panel", children)
