module demo/model

import library/bridge
import library/dialog
import library/search
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

pub effect fun confirm_action(message : string) : bool
pub effect fun audit(message : string) : ()
pub effect val current_filter : string
pub effect val current_operator : string
pub effect fun wait_ms(delay : int) : ()
pub effect fun fetch_lab_snapshot() : lab_snapshot
pub effect fun post_lab_reply(incident_id : int, message : string) : string
pub effect fun now_label() : string

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

fun incident_expanded_slot(incident_id : int) : state_slot
  named_slot("lab/incidents/" ++ incident_id.show, "expanded")

fun incident_draft_slot(incident_id : int) : state_slot
  named_slot("lab/incidents/" ++ incident_id.show, "draft")

fun incident_expanded(item : workflow_lab, incident_id : int) : <div> bool
  slot_flag(item.local_tree, incident_expanded_slot(incident_id), False)

fun incident_draft(item : workflow_lab, incident_id : int) : <div> string
  slot_text(item.local_tree, incident_draft_slot(incident_id), "")

fun task_visible(item : task) : current_filter bool
  if current_filter == "active" then not(item.done)
  else if current_filter == "done" then item.done
  else True

pub fun visible_tasks(tasks : list<task>) : <current_filter,div> list<task>
  filter(tasks, task_visible)

pub fun tasks_for(filter_name : string, tasks : list<task>) : <div> list<task>
  with val current_filter = filter_name
  visible_tasks(tasks)

// Route changes remain data-only; render-time hooks now decide whether to execute browser effects.
pub fun reduce_click(payload : string, item : model) : <confirm_action,audit,current_operator,wait_ms,fetch_lab_snapshot,post_lab_reply,now_label,div> model
  if payload == "route-overview" then item(route_name = normalize_route("overview"))
  else if payload == "route-todo" then item(route_name = normalize_route("todo"))
  else if payload == "route-lab" then item(route_name = normalize_route("lab"))
  else if payload == "route-lab-board" then item(route_name = normalize_route("lab-board"))
  else if payload == "route-lab-search" then item(route_name = normalize_route("lab-search"))
  else if payload == "route-lab-bridge" then item(route_name = normalize_route("lab-bridge"))
  else if payload == "route-effects" then item(route_name = normalize_route("effects"))
  else if payload == "route-effects-core" then item(route_name = normalize_route("effects-core"))
  else if payload == "route-effects-dialogs" then item(route_name = normalize_route("effects-dialogs"))
  else if payload == "route-effects-workflow" then item(route_name = normalize_route("effects-workflow"))
  else if payload == "route-effects-state" then item(route_name = normalize_route("effects-state"))
  else if payload == "route-effects-timer" then item(route_name = normalize_route("effects-timer"))
  else if payload == "route-checks" then item(route_name = normalize_route("checks"))
  else item(notice = "Unknown action: " ++ payload)

pub fun reduce_input(channel : string, value : string, item : model) : <div> model
  item(notice = "Unhandled input channel: " ++ channel ++ " = " ++ value)
