module demo/lab/view

import demo/model
import demo/lab/events
import demo/lab/search
import demo/seed
import demo/shared
import demo/lab/state
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
    text_class("p", "bridge-transition-note", "case-detail", "Currently showing `" ++ demo.visible_case ++ "` while the browser bridge resolves `" ++ demo.requested_case ++ "` in the background."),
    node_class("div", "bridge-transition-rail", "bridge-transition-rail", [
      text_class("span", "bridge-visible-token", "bridge-token bridge-token-current", "visible: " ++ demo.visible_case),
      text_class("span", "bridge-arrow-token", "bridge-arrow-token", "->"),
      text_class("span", "bridge-requested-token", "bridge-token bridge-token-next", "next: " ++ demo.requested_case),
    ]),
  ])

fun bridge_detail_node(case_item : bridge_case, demo : suspense_bridge_demo) : <div> vnode
  if demo.detail_status == "ready" then
    node_class("div", "bridge-detail", "bridge-detail-card", [
      text_class("strong", "bridge-detail-title", "section-title", bridge_case/detail_title(case_item)),
      text_class("p", "bridge-detail-note", "case-detail", "Nested boundary resolved after the outer shell became visible."),
      node_class("ul", "bridge-detail-list", "activity-list", render_bridge_detail_lines(bridge_case/detail_lines(case_item))),
    ])
  else
    bridge_fallback("bridge-detail-fallback", "Nested fallback", "Shell is visible, but the diagnostic trace is still suspended through the browser callback bridge.", "bridge-detail-fallback")

fun bridge_shell_node(case_item : bridge_case, demo : suspense_bridge_demo) : <div> vnode
  val is_refreshing = demo.shell_status == "refreshing"
  val shell_class = if is_refreshing then "bridge-shell-card bridge-shell-refreshing" else "bridge-shell-card"
  val status_text = if is_refreshing then "showing stale shell while requesting `" ++ demo.requested_case ++ "`" else "outer boundary resolved"
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
  val demo = lab.bridge_demo
  val requested_case = demo.requested_case
  val visible_case = demo.visible_case
  val selected_case = if visible_case == "" then requested_case else visible_case
  val requested_note = match bridge_case_by_name(requested_case)
    Just(case_item) -> bridge_case/stage_note(case_item)
    Nothing -> "Select a bridge case to start the suspense-like demo."
  val stage_node = match bridge_case_by_name(selected_case)
    Just(case_item) -> if visible_case == "" && demo.shell_status != "ready" then
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
        summary_chip("Shell", demo.shell_status),
        summary_chip("Detail", demo.detail_status),
      ]),
    ]),
    node_class("div", "bridge-case-row", "button-row bridge-case-row", render_bridge_case_buttons(bridge_demo_cases(), requested_case, visible_case)),
    stage_node,
  ])

fun search_case_button(item : search_case, requested_query : string, visible_query : string) : <div> vnode
  val query = search_case/query(item)
  val class_name =
    if query == visible_query then "button button-active"
    else if query == requested_query then "button button-primary bridge-button-pending"
    else "button"
  button_class("search-case-" ++ query, class_name, [dispatch_lab_click(Search_for(query))], search_case/label(item))

fun render_search_case_buttons(items : list<search_case>, requested_query : string, visible_query : string) : <div> list<vnode>
  map(items, fn(item) search_case_button(item, requested_query, visible_query))

fun render_menu_keyword_pills(items : list<string>, key_prefix : string) : <div> list<vnode>
  map-indexed(items, fn(index, item) text_class("span", key_prefix ++ "-keyword-" ++ index.show, "search-keyword-chip", item))

fun search_menu_card(item : search_menu_item, query : string) : <div> vnode
  val is_match = search_menu_matches_query(item, query)
  val button_class_name = if query == search_menu_item/query_hint(item) then "button button-active" else if is_match then "button button-primary" else "button"
  node_class("article", "search-menu-" ++ search_menu_item/query_hint(item) ++ "-" ++ search_menu_item/title(item), if is_match then "search-menu-card search-menu-card-match" else "search-menu-card", [
    node_class("div", "search-menu-head-" ++ search_menu_item/query_hint(item), "search-menu-head", [
      node_class("div", "search-menu-copy-" ++ search_menu_item/query_hint(item), "stack", [
        text_class("strong", "search-menu-title-" ++ search_menu_item/query_hint(item), "section-title", search_menu_item/title(item)),
        text_class("p", "search-menu-route-" ++ search_menu_item/query_hint(item), "mono", search_menu_item/route_hint(item)),
      ]),
      button_class("search-menu-trigger-" ++ search_menu_item/query_hint(item), button_class_name, [dispatch_lab_click(Search_for(search_menu_item/query_hint(item)))], "Search " ++ search_menu_item/query_hint(item)),
    ]),
    text_class("p", "search-menu-note-" ++ search_menu_item/query_hint(item), "case-detail", search_menu_item/note(item)),
    node_class("div", "search-menu-keywords-" ++ search_menu_item/query_hint(item), "search-menu-keywords", render_menu_keyword_pills(search_menu_item/keywords(item), search_menu_item/query_hint(item))),
  ])

fun render_search_menu(items : list<search_menu_item>, query : string) : <div> list<vnode>
  map(items, fn(item) search_menu_card(item, query))

fun search_auto_banner(demo : search_demo) : <div> vnode
  node_class("div", "search-auto-banner", "bridge-transition-banner search-auto-banner", [
    node_class("div", "search-auto-head", "bridge-transition-head", [
      text_class("strong", "search-auto-title", "bridge-fallback-title", "Typing pause armed an automatic search"),
      text_class("span", "search-auto-status", "incident-status incident-status-investigating", "armed"),
    ]),
    text_class("p", "search-auto-note", "case-detail", "If no newer input arrives, the browser bridge will auto-start the current menu query after the debounce window."),
  ])

fun render_search_result_lines(lines : list<string>) : <div> list<vnode>
  map-indexed(lines, fn(index, line) text_class("li", "search-result-" ++ index.show, "activity-item", line))

fun search_timeout_banner(demo : search_demo) : <div> vnode
  node_class("div", "search-timeout-banner", "bridge-transition-banner search-timeout-banner", [
    node_class("div", "search-timeout-head", "bridge-transition-head", [
      text_class("strong", "search-timeout-title", "bridge-fallback-title", "Timeout fired before the current result settled"),
      text_class("span", "search-timeout-status", "incident-status incident-severity-p2", "timeout"),
    ]),
    text_class("p", "search-timeout-note", "case-detail", "The current request is late. Suspense-lite keeps stale hits visible when possible and still accepts the same request if it eventually resolves."),
  ])

fun search_transition_banner(demo : search_demo) : <div> vnode
  node_class("div", "search-transition-banner", "bridge-transition-banner", [
    node_class("div", "search-transition-head", "bridge-transition-head", [
      text_class("strong", "search-transition-title", "bridge-fallback-title", "Refreshing search keeps stale hits visible"),
      text_class("span", "search-transition-status", "incident-status incident-status-investigating", "refreshing"),
    ]),
    text_class("p", "search-transition-note", "case-detail", "Showing results for `" ++ demo.visible_query ++ "` while querying `" ++ demo.requested_query ++ "` in the background."),
  ])

fun search_result_stage(demo : search_demo) : <div> vnode
  if demo.visible_query == "" && demo.status == "timed_out" then
    bridge_fallback("search-timeout-fallback", "Search timeout", demo.stage_note, "search-timeout-fallback")
  else if demo.visible_query == "" && demo.status != "ready" then
    bridge_fallback("search-pending-fallback", "Search fallback", demo.stage_note, "search-pending-fallback")
  else
    node_class("article", "search-result-stage", if demo.status == "refreshing" then "bridge-shell-card search-stage search-stage-refreshing" else "bridge-shell-card search-stage", [
      node_class("div", "search-stage-head", "bridge-shell-head", [
        node_class("div", "search-stage-copy", "stack", [
          text_class("strong", "search-stage-title", "section-title", "Results for `" ++ demo.visible_query ++ "`"),
          text_class("p", "search-stage-note", "case-detail", demo.stage_note),
        ]),
        node_class("div", "search-stage-badges", "bridge-shell-badges", [
          text_class("span", "search-stage-status", "incident-status incident-status-investigating", demo.status),
        ]),
      ]),
      if demo.status == "refreshing" then search_transition_banner(demo) else node_class("div", "search-transition-placeholder", "stack", Nil),
      if demo.auto_status == "armed" then search_auto_banner(demo) else node_class("div", "search-auto-placeholder", "stack", Nil),
      if demo.timeout_status == "timed_out" then search_timeout_banner(demo) else node_class("div", "search-timeout-placeholder", "stack", Nil),
      node_class("ul", "search-results", "activity-list", render_search_result_lines(demo.results)),
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
    node_class("div", "search-case-row", "button-row bridge-case-row", render_search_case_buttons(search_demo_cases(), demo.requested_query, demo.visible_query)),
    node_class("div", "search-menu-grid", "search-menu-grid", render_search_menu(search_menu_items(), current_query)),
    search_result_stage(demo),
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
