module demo/model

import respo/state

pub type incident_severity
  Severity_p1
  Severity_p2
  Severity_p3

pub fun show_severity(s : incident_severity) : string
  match s
    Severity_p1 -> "p1"
    Severity_p2 -> "p2"
    Severity_p3 -> "p3"

pub type incident_status
  Status_firing
  Status_investigating
  Status_acked

pub fun show_status(s : incident_status) : string
  match s
    Status_firing -> "firing"
    Status_investigating -> "investigating"
    Status_acked -> "acked"

pub type dialog_kind
  Dialog_none
  Dialog_alert
  Dialog_prompt
  Dialog_dialog
  Dialog_drawer

pub fun show_kind(k : dialog_kind) : string
  match k
    Dialog_none -> "none"
    Dialog_alert -> "alert"
    Dialog_prompt -> "prompt"
    Dialog_dialog -> "dialog"
    Dialog_drawer -> "drawer"

pub effect fun confirm_action(message : string) : bool
pub effect fun audit(message : string) : ()
pub effect val current_filter : string
pub effect val current_operator : string
pub effect fun wait_ms(delay : int) : ()
pub effect fun fetch_lab_snapshot() : lab_snapshot
pub effect fun post_lab_reply(incident_id : int, message : string) : string
pub effect fun now_label() : string
pub effect fun request_bridge_resource(payload : string, delay : int) : ()

pub alias browser_event_effect = <audit,confirm_action,current_operator,fetch_lab_snapshot,now_label,post_lab_reply,request_bridge_resource,wait_ms>

pub struct task
  id : int
  title : string
  done : bool

pub struct incident
  id : int
  title : string
  severity : incident_severity
  status : incident_status
  summary : string
  server_note : string
  updated_by : string

pub struct lab_snapshot
  incidents : list<incident>
  summary : string

pub struct suspense_bridge_demo
  requested_case : string
  visible_case : string
  shell_status : string
  detail_status : string
  shell_request_id : int
  detail_request_id : int

pub struct dialog_demo
  kind : dialog_kind
  title : string
  message : string
  prompt_value : string
  prompt_error : string
  result_note : string
  activity_log : list<string>

pub struct search_demo
  query_input : string
  requested_query : string
  visible_query : string
  status : string
  timeout_status : string
  auto_status : string
  request_id : int
  auto_request_id : int
  results : list<string>
  stage_note : string

pub struct workflow_lab
  incidents : list<incident>
  activity_log : list<string>
  local_tree : list<state_entry>
  sync_status : string
  last_sync_label : string
  bridge_demo : suspense_bridge_demo
  search_demo : search_demo

pub struct model
  tasks : list<task>
  draft : string
  next_id : int
  filter_name : string
  notice : string
  route_name : string
  todo_local_tree : list<state_entry>
  lab : workflow_lab
  dialog : dialog_demo

pub fun set_next_id(item : model, next_id : int) : model
  item(next_id = next_id)

pub fun set_todo_local_tree(item : model, todo_local_tree : list<state_entry>) : model
  item(todo_local_tree = todo_local_tree)

pub fun set_tasks(item : model, tasks : list<task>) : model
  item(tasks = tasks)

pub fun initial_bridge_demo(requested_case : string) : suspense_bridge_demo
  Suspense_bridge_demo(requested_case, "", "idle", "idle", 0, 0)

pub fun initial_dialog_demo() : dialog_demo
  Dialog_demo(Dialog_none, "", "", "", "", "No overlay interaction yet.", Nil)

pub fun initial_search_demo(query_input : string) : search_demo
  Search_demo(query_input, "", "", "idle", "idle", "idle", 0, 0, Nil, "Type a query, pause to auto-search the menu catalog, keep stale results visible during refresh, and let timeout race against the mocked server response.")

pub fun dialog_is_open(item : dialog_demo) : <div> bool
  match item.kind
    Dialog_none -> False
    _ -> True

pub fun normalize_route(route_name : string) : string
  if route_name == "todo" then "todo"
  else if route_name == "lab" || route_name == "lab-board" then "lab-board"
  else if route_name == "lab-search" then "lab-search"
  else if route_name == "lab-bridge" then "lab-bridge"
  else if route_name == "effects" || route_name == "effects-core" then "effects-core"
  else if route_name == "effects-dialogs" then "effects-dialogs"
  else if route_name == "effects-workflow" then "effects-workflow"
  else if route_name == "effects-state" then "effects-state"
  else if route_name == "effects-timer" then "effects-timer"
  else if route_name == "checks" then "checks"
  else "overview"

pub fun route_section(route_name : string) : string
  if route_name == "todo" then "todo"
  else if route_name == "lab-board" || route_name == "lab-search" || route_name == "lab-bridge" then "lab"
  else if route_name == "effects-core" || route_name == "effects-dialogs" || route_name == "effects-workflow" || route_name == "effects-state" || route_name == "effects-timer" then "effects"
  else if route_name == "checks" then "checks"
  else "overview"

pub fun route_is_lab(route_name : string) : bool
  route_section(route_name) == "lab"

pub fun route_is_effects(route_name : string) : bool
  route_section(route_name) == "effects"

pub fun task_toggle_id(item : task) : string
  "toggle-" ++ task/id(item).show

pub fun task_remove_id(item : task) : string
  "remove-" ++ task/id(item).show

pub fun task_edit_id(item : task) : string
  "edit-" ++ task/id(item).show

pub fun task_save_id(item : task) : string
  "save-" ++ task/id(item).show

pub fun task_cancel_id(item : task) : string
  "cancel-" ++ task/id(item).show

pub fun task_draft_channel(item : task) : string
  "task-draft-" ++ task/id(item).show

pub fun incident_toggle_payload(item : incident) : string
  "lab-toggle-" ++ incident/id(item).show

pub fun incident_draft_channel(item : incident) : string
  "lab-draft-" ++ incident/id(item).show

pub fun incident_send_payload(item : incident) : string
  "lab-send-" ++ incident/id(item).show

fun incident_state_base(incident_id : int) : string
  "lab/incidents/" ++ incident_id.show

fun incident_expanded_slot(incident_id : int) : state_slot
  named_slot(incident_state_base(incident_id), "expanded")

fun incident_draft_slot(incident_id : int) : state_slot
  named_slot(incident_state_base(incident_id), "draft")

fun incident_expanded(item : workflow_lab, incident_id : int) : <div> bool
  slot_flag(item.local_tree, incident_expanded_slot(incident_id), False)

fun incident_draft(item : workflow_lab, incident_id : int) : <div> string
  slot_text(item.local_tree, incident_draft_slot(incident_id), "")

pub fun has_done_tasks(tasks : list<task>) : <div> bool
  any(tasks, fn(i) i.done)

pub fun count_all(tasks : list<task>) : <div> int
  length(tasks)

pub fun count_done(tasks : list<task>) : <div> int
  length(filter(tasks, fn(i) i.done))

fun count_incidents(items : list<incident>) : <div> int
  length(items)

fun count_open_incidents(items : list<incident>) : <div> int
  length(filter(items, fn(item) match item.status { Status_acked -> False; _ -> True }))

fun count_lines(lines : list<string>) : <div> int
  length(lines)

fun count_non_empty_drafts(item : workflow_lab, incidents : list<incident>) : <div> int
  length(filter(incidents, fn(incident) incident_draft(item, incident/id(incident)) != ""))

pub fun lab_incident_count(item : workflow_lab) : <div> int
  count_incidents(item.incidents)

pub fun lab_open_count(item : workflow_lab) : <div> int
  count_open_incidents(item.incidents)

pub fun lab_draft_count(item : workflow_lab) : <div> int
  count_non_empty_drafts(item, item.incidents)

pub fun lab_activity_count(item : workflow_lab) : <div> int
  count_lines(item.activity_log)

pub fun lab_local_count(item : workflow_lab) : <div> int
  count_entries(item.local_tree)

fun task_visible(item : task) : current_filter bool
  if current_filter == "active" then not(item.done)
  else if current_filter == "done" then item.done
  else True

pub fun visible_tasks(tasks : list<task>) : <current_filter,div> list<task>
  filter(tasks, task_visible)

pub fun tasks_for(filter_name : string, tasks : list<task>) : <div> list<task>
  with val current_filter = filter_name
  visible_tasks(tasks)

pub fun find_incident_by_id(target_id : int, items : list<incident>) : <div> maybe<incident>
  find(items, fn(item) target_id == incident/id(item))

pub fun find_task_by_id(target_id : int, tasks : list<task>) : <div> maybe<task>
  find(tasks, fn(item) target_id == task/id(item))

pub fun lab_incident_by_id(item : workflow_lab, target_id : int) : <div> maybe<incident>
  find_incident_by_id(target_id, item.incidents)

pub fun set_notice(item : model, notice : string) : model
  item(notice = notice)

pub fun set_filter(item : model, filter_name : string) : model
  item(filter_name = filter_name, notice = "Primary list switched to `" ++ filter_name ++ "`.")

pub fun set_draft(item : model, draft : string) : model
  item(draft = draft)

pub fun set_lab(item : model, lab : workflow_lab) : model
  item(lab = lab)

pub fun set_dialog(item : model, dialog : dialog_demo) : model
  item(dialog = dialog)

pub fun set_route(item : model, route_name : string) : model
  item(route_name = normalize_route(route_name))

// Route changes remain data-only; render-time hooks now decide whether to execute browser effects.
pub fun reduce_click(payload : string, item : model) : <confirm_action,audit,current_operator,wait_ms,fetch_lab_snapshot,post_lab_reply,now_label,div> model
  if payload == "route-overview" then set_route(item, "overview")
  else if payload == "route-todo" then set_route(item, "todo")
  else if payload == "route-lab" then set_route(item, "lab")
  else if payload == "route-lab-board" then set_route(item, "lab-board")
  else if payload == "route-lab-search" then set_route(item, "lab-search")
  else if payload == "route-lab-bridge" then set_route(item, "lab-bridge")
  else if payload == "route-effects" then set_route(item, "effects")
  else if payload == "route-effects-core" then set_route(item, "effects-core")
  else if payload == "route-effects-dialogs" then set_route(item, "effects-dialogs")
  else if payload == "route-effects-workflow" then set_route(item, "effects-workflow")
  else if payload == "route-effects-state" then set_route(item, "effects-state")
  else if payload == "route-effects-timer" then set_route(item, "effects-timer")
  else if payload == "route-checks" then set_route(item, "checks")
  else set_notice(item, "Unknown action: " ++ payload)

pub fun reduce_input(channel : string, value : string, item : model) : <div> model
  set_notice(item, "Unhandled input channel: " ++ channel ++ " = " ++ value)
