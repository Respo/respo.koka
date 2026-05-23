module demo/model

import library/bridge
import library/dialog
import library/route
import library/search
import explore/react/state

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
  app_local_tree : list<state_entry>
  lab : workflow_lab
  dialog : dialog_demo

fun task_visible(item : task) : current_filter bool
  if current_filter == "active" then not(item.done)
  else if current_filter == "done" then item.done
  else True

pub fun visible_tasks(tasks : list<task>) : <current_filter,div> list<task>
  filter(tasks, task_visible)

pub fun tasks_for(filter_name : string, tasks : list<task>) : <div> list<task>
  with val current_filter = filter_name
  visible_tasks(tasks)

pub fun handle_route_click(payload : string, item : model) : <div> maybe<model>
  route_click_target(payload).map(fn(route_name) item(route_name = route_name))

// Route changes remain data-only; render-time hooks now decide whether to execute browser effects.
pub fun reduce_click(payload : string, item : model) : <confirm_action,audit,current_operator,wait_ms,fetch_lab_snapshot,post_lab_reply,now_label,div> model
  match handle_route_click(payload, item)
    Just(next_item) -> next_item
    Nothing -> item(notice = "Unknown action: " ++ payload)

pub fun reduce_input(channel : string, value : string, item : model) : <div> model
  item(notice = "Unhandled input channel: " ++ channel ++ " = " ++ value)
