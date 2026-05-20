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

alias lab_view_effect = <push_hook_scope,pop_hook_scope,use_state,register_listener<model,browser_event_effect>,div>

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
  component(incident_hook_scope(iid), fn() {
    val item_scope = incident_hook_scope(iid)
    val expanded = use_state(flag_state_codec, False)
    val draft = use_state(text_state_codec, "")
    val toggle_label = if expanded then "Collapse" else "Expand"
    val preview_text = if draft == "" then "local draft: <empty>" else "local draft: " ++ draft
    val collapsed_text = if draft == "" then "Draft is local and still empty." else "Draft saved locally for this card."
    val detail_node = if expanded then
      node_class("div", "incident-detail-" ++ iid.show, "incident-detail-grid", [
        text_class("p", "incident-remote-" ++ iid.show, "mono", "server: " ++ item.server_note),
        text_class("p", "incident-owner-" ++ iid.show, "mono", "updated by: " ++ item.updated_by),
        text_class("p", "incident-draft-preview-" ++ iid.show, "mono", preview_text),
      ])
    else
      text_class("p", "incident-collapsed-" ++ iid.show, "mono", collapsed_text)
    node_class("article", "incident-" ++ iid.show, "incident-card", [
      node_class("div", "incident-head-" ++ iid.show, "incident-head", [
        node_class("div", "incident-title-wrap-" ++ iid.show, "incident-title-wrap", [
          text_class("strong", "incident-title-" ++ iid.show, "incident-title", item.title),
          text_class("span", "incident-summary-" ++ iid.show, "case-detail", item.summary),
        ]),
        node_class("div", "incident-badges-" ++ iid.show, "incident-badges", [
          text_class("span", "incident-severity-" ++ iid.show, severity_class(item), item.severity.show_severity),
          text_class("span", "incident-status-" ++ iid.show, status_class(item), item.status.show_status),
        ]),
      ]),
      node_class("div", "incident-controls-" ++ iid.show, "incident-controls", [
        button_class("lab-toggle-" ++ iid.show, "button", [on_named_click(item_scope, "toggle-expanded", fn(owner) commit_lab_tree(owner, fn() toggle_local_lab_expanded(owner, iid)))], toggle_label),
        text_input("lab-draft-" ++ iid.show, "input incident-input", draft, "Local reply draft, per card...", Nil, [
          on_named_input(item_scope, "draft-input", fn(value, owner) commit_lab_tree(owner, fn() set_local_lab_draft(owner, iid, value))),
          dispatch_lab_enter(Send_reply(iid)),
        ]),
        button_class("lab-send-" ++ iid.show, "button button-primary", [dispatch_lab_click(Send_reply(iid))], "Send reply"),
      ]),
      detail_node,
    ])
  })

fun render_incident_cards(items : list<incident>) : lab_view_effect list<vnode>
  map(items, incident_card)

fun incident_grid(lab : workflow_lab) : lab_view_effect vnode
  node_class("div", "incident-grid", "incident-grid", render_incident_cards(lab.incidents))

fun render_activity_items(lines : list<string>) : <div> list<vnode>
  map-indexed(lines, fn(index, line) text_class("li", "activity-" ++ index.show, "activity-item", line))

fun activity_panel(lab : workflow_lab) : <div> vnode
  node_class("aside", "lab-activity", "mini-panel activity-panel", [
    text_node("strong", "lab-activity-title", empty_props, "Workflow activity"),
    text_class("p", "lab-activity-note", "case-detail", "Each sync or reply appends a line that can be asserted in tests."),
    node_class("ul", "lab-activity-list", "activity-list", render_activity_items(lab.activity_log)),
  ])

fun suspense_bridge_panel(lab : workflow_lab) : <div> vnode
  val demo = lab.bridge_demo
  val requested_case = demo.requested_case
  val visible_case = demo.visible_case
  val selected_case = if visible_case == "" then requested_case else visible_case
  val requested_note = match bridge_case_by_name(requested_case)
    Just(case_item) -> bridge_case/stage_note(case_item)
    Nothing -> "Select a bridge case to start the suspense-like demo."
  val stage_node = render_bridge_stage(bridge_case_by_name(selected_case), requested_note, requested_case, visible_case, demo.shell_status, demo.detail_status)
  node_class("section", "lab-bridge", "bridge-panel", [
    node_class("div", "bridge-panel-head", "bridge-panel-head", [
      node_class("div", "bridge-panel-copy", "stack", [
        text_class("strong", "bridge-panel-title", "section-title", "Suspense-like bridge demo"),
        text_class("p", "bridge-panel-note", "case-detail", "This keeps stale shell content visible while a browser callback resolves the next case, then reveals nested detail through a second fallback."),
      ]),
      node_class("div", "bridge-meta", "summary-row bridge-meta", [
        summary_chip("Requested", requested_case),
        summary_chip("Visible", if visible_case == "" then "<fallback>" else visible_case),
        summary_chip("Shell", demo.shell_status),
        summary_chip("Detail", demo.detail_status),
      ]),
    ]),
    node_class("div", "bridge-case-row", "button-row bridge-case-row", render_bridge_case_buttons(bridge_demo_cases(), requested_case, visible_case, fn(case_name) dispatch_lab_click(Load_bridge_case(case_name)))),
    stage_node,
  ])

fun suspense_search_panel(lab : workflow_lab) : <div> vnode
  val demo = lab.search_demo
  val current_query = if trim(demo.query_input) == "" then demo.visible_query else trim(demo.query_input)
  node_class("section", "lab-search", "bridge-panel search-panel", [
    node_class("div", "search-panel-head", "bridge-panel-head", [
      node_class("div", "search-panel-copy", "stack", [
        text_class("strong", "search-panel-title", "section-title", "Suspense-lite search demo"),
        text_class("p", "search-panel-note", "case-detail", "User input stays interactive while a debounced auto-search, mocked server results, and timeout callbacks race through the bridge layer against a menu catalog."),
      ]),
      node_class("div", "search-meta", "summary-row bridge-meta", [
        summary_chip("Requested", if demo.requested_query == "" then "<none>" else demo.requested_query),
        summary_chip("Visible", if demo.visible_query == "" then "<fallback>" else demo.visible_query),
        summary_chip("Status", demo.status),
        summary_chip("Timeout", demo.timeout_status),
        summary_chip("Auto", demo.auto_status),
      ]),
    ]),
    node_class("div", "search-controls", "composer-row", [
      text_input(search_query_channel(), "input", demo.query_input, "Pause on `edge`, `queue`, `image`, `dialog` ...", Nil, [input_listener(search_query_channel()), dispatch_lab_enter(Submit_search)]),
      button_class(search_submit_payload(), "button button-primary", [dispatch_lab_click(Submit_search)], "Run search"),
      text_class("span", "search-summary", "mono", "request #" ++ demo.request_id.show ++ " / auto #" ++ demo.auto_request_id.show),
    ]),
    node_class("div", "search-case-row", "button-row bridge-case-row", render_search_case_buttons(search_demo_cases(), demo.requested_query, demo.visible_query, fn(query) dispatch_lab_click(Search_for(query)))),
    node_class("div", "search-menu-grid", "search-menu-grid", render_search_menu(search_menu_items(), current_query, fn(query) dispatch_lab_click(Search_for(query)))),
    render_search_stage(demo, render_bridge_fallback),
  ])

fun lab_panel_note(route_name : string) : string
  if route_name == "lab-search" then "Search is isolated here so debounced auto-run, timeout racing, stale-result retention, and the menu catalog are easier to inspect by themselves."
  else if route_name == "lab-bridge" then "Bridge is isolated here so the staged shell/detail suspense-like behavior is not competing with the workflow board or search demo."
  else "Board keeps the incident workflow, local drafts, activity log, and staged sync actions together without the search and bridge demos crowding the same page."

fun lab_panel_sections(route_name : string, lab : workflow_lab) : lab_view_effect list<vnode>
  if route_name == "lab-search" then
    [suspense_search_panel(lab)]
  else if route_name == "lab-bridge" then
    [suspense_bridge_panel(lab)]
  else
    [
      node_class("div", "lab-actions", "button-row", [
        button_class("lab-load", "button", [dispatch_lab_click(Load_board)], "Load mock board"),
        button_class("lab-sync", "button button-primary", [dispatch_lab_click(Run_sync)], "Run staged sync"),
        text_class("span", "lab-status", "mono", "status: " ++ lab.sync_status),
      ]),
      node_class("div", "lab-body", "lab-body-grid", [
        incident_grid(lab),
        activity_panel(lab),
      ]),
    ]

pub fun render_lab_panel(item : model) : lab_view_effect vnode
  val lab = item.lab
  val children = [
    node_class("div", "lab-summary", "summary-row", [
      summary_chip("Incidents", length(lab.incidents).show),
      summary_chip("Open", length(filter(lab.incidents, fn(incident_item) match incident_item.status { Status_acked -> False; _ -> True })).show),
      summary_chip("Drafts", length(filter(lab.incidents, fn(incident_item) lab_incident_draft(lab, incident/id(incident_item)) != "")).show),
      summary_chip("Local cells", count_entries(lab.local_tree).show),
      summary_chip("Last sync", lab.last_sync_label),
    ]),
  ] ++ lab_panel_sections(item.route_name, lab)
  panel("Workflow lab", lab_panel_note(item.route_name), "lab", "lab-panel", children)
