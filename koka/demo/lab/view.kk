module demo/lab/view

import demo/model
import demo/lab/events
import demo/seed
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

fun bridge_case_button(item : bridge_case, requested_case : string, visible_case : string) : <div> vnode
  val case_name = bridge_case/name(item)
  val class_name =
    if case_name == visible_case then "button button-active"
    else if case_name == requested_case then "button button-primary bridge-button-pending"
    else "button"
  button_class("bridge-case-" ++ case_name, class_name, [dispatch_lab_click(Load_bridge_case(case_name))], bridge_case/label(item))

fun render_bridge_case_buttons(items : list<bridge_case>, requested_case : string, visible_case : string) : <div> list<vnode>
  map(items, fn(item) bridge_case_button(item, requested_case, visible_case))

fun bridge_fallback(key : string, title : string, note : string, class_name : string) : <div> vnode
  node_class("div", key, "bridge-fallback " ++ class_name, [
    text_class("strong", key ++ "-title", "bridge-fallback-title", title),
    text_class("p", key ++ "-note", "case-detail", note),
    node_class("div", key ++ "-bars", "bridge-fallback-bars", [
      node_class("span", key ++ "-bar-1", "bridge-bar bridge-bar-wide", Nil),
      node_class("span", key ++ "-bar-2", "bridge-bar bridge-bar-mid", Nil),
      node_class("span", key ++ "-bar-3", "bridge-bar bridge-bar-short", Nil),
    ]),
  ])

fun render_bridge_detail_lines(lines : list<string>) : <div> list<vnode>
  map-indexed(lines, fn(index, line) text_class("li", "bridge-detail-" ++ index.show, "activity-item", line))

fun bridge_transition_banner(demo : suspense_bridge_demo) : <div> vnode
  node_class("div", "bridge-transition-banner", "bridge-transition-banner", [
    node_class("div", "bridge-transition-head", "bridge-transition-head", [
      text_class("strong", "bridge-transition-title", "bridge-fallback-title", "Transition keeps stale content visible"),
      text_class("span", "bridge-transition-status", "incident-status incident-status-investigating", "refreshing"),
    ]),
    text_class("p", "bridge-transition-note", "case-detail", "Currently showing `" ++ bridge_visible_case(demo) ++ "` while the browser bridge resolves `" ++ bridge_requested_case(demo) ++ "` in the background."),
    node_class("div", "bridge-transition-rail", "bridge-transition-rail", [
      text_class("span", "bridge-visible-token", "bridge-token bridge-token-current", "visible: " ++ bridge_visible_case(demo)),
      text_class("span", "bridge-arrow-token", "bridge-arrow-token", "->"),
      text_class("span", "bridge-requested-token", "bridge-token bridge-token-next", "next: " ++ bridge_requested_case(demo)),
    ]),
  ])

fun bridge_detail_node(case_item : bridge_case, demo : suspense_bridge_demo) : <div> vnode
  if bridge_detail_status(demo) == "ready" then
    node_class("div", "bridge-detail", "bridge-detail-card", [
      text_class("strong", "bridge-detail-title", "section-title", bridge_case/detail_title(case_item)),
      text_class("p", "bridge-detail-note", "case-detail", "Nested boundary resolved after the outer shell became visible."),
      node_class("ul", "bridge-detail-list", "activity-list", render_bridge_detail_lines(bridge_case/detail_lines(case_item))),
    ])
  else
    bridge_fallback("bridge-detail-fallback", "Nested fallback", "Shell is visible, but the diagnostic trace is still suspended through the browser callback bridge.", "bridge-detail-fallback")

fun bridge_shell_node(case_item : bridge_case, demo : suspense_bridge_demo) : <div> vnode
  val is_refreshing = bridge_shell_status(demo) == "refreshing"
  val shell_class = if is_refreshing then "bridge-shell-card bridge-shell-refreshing" else "bridge-shell-card"
  val status_text = if is_refreshing then "showing stale shell while requesting `" ++ bridge_requested_case(demo) ++ "`" else "outer boundary resolved"
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
      bridge_transition_banner(demo),
      text_class("p", "bridge-shell-stage-note", "bridge-state-note", bridge_case/stage_note(case_item)),
      bridge_detail_node(case_item, demo),
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
      bridge_detail_node(case_item, demo),
    ]
  node_class("article", "bridge-shell", shell_class, body_children)

fun suspense_bridge_panel(lab : workflow_lab) : <div> vnode
  val demo = lab_bridge_demo(lab)
  val requested_case = bridge_requested_case(demo)
  val visible_case = bridge_visible_case(demo)
  val selected_case = if visible_case == "" then requested_case else visible_case
  val requested_note = match bridge_case_by_name(requested_case)
    Just(case_item) -> bridge_case/stage_note(case_item)
    Nothing -> "Select a bridge case to start the suspense-like demo."
  val stage_node = match bridge_case_by_name(selected_case)
    Just(case_item) -> if visible_case == "" && bridge_shell_status(demo) != "ready" then
      bridge_fallback("bridge-shell-fallback", "Outer fallback", requested_note, "bridge-shell-fallback")
    else
      bridge_shell_node(case_item, demo)
    Nothing -> node_class("div", "bridge-empty", "bridge-empty", [
      text_class("strong", "bridge-empty-title", "section-title", "Suspense-like bridge demo"),
      text_class("p", "bridge-empty-note", "case-detail", "Select a case to trigger a browser callback that resolves the shell and nested diagnostics in two stages."),
    ])
  node_class("section", "lab-bridge", "bridge-panel", [
    node_class("div", "bridge-panel-head", "bridge-panel-head", [
      node_class("div", "bridge-panel-copy", "stack", [
        text_class("strong", "bridge-panel-title", "section-title", "Suspense-like bridge demo"),
        text_class("p", "bridge-panel-note", "case-detail", "This keeps stale shell content visible while a browser callback resolves the next case, then reveals nested detail through a second fallback."),
      ]),
      node_class("div", "bridge-meta", "summary-row bridge-meta", [
        summary_chip("Requested", requested_case),
        summary_chip("Visible", if visible_case == "" then "<fallback>" else visible_case),
        summary_chip("Shell", bridge_shell_status(demo)),
        summary_chip("Detail", bridge_detail_status(demo)),
      ]),
    ]),
    node_class("div", "bridge-case-row", "button-row bridge-case-row", render_bridge_case_buttons(bridge_demo_cases(), requested_case, visible_case)),
    stage_node,
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
    suspense_bridge_panel(lab),
    node_class("div", "lab-body", "lab-body-grid", [
      incident_grid(lab),
      activity_panel(lab),
    ]),
  ])
