module demo/model

import respo/state

pub effect fun confirm_action(message : string) : bool
pub effect fun audit(message : string) : ()
pub effect val current_filter : string
pub effect val current_operator : string
pub effect fun wait_ms(delay : int) : ()
pub effect fun fetch_lab_snapshot() : lab_snapshot
pub effect fun post_lab_reply(incident_id : int, message : string) : string
pub effect fun now_label() : string

pub alias browser_event_effect = <audit,confirm_action,current_operator,fetch_lab_snapshot,now_label,post_lab_reply,wait_ms>

pub struct task
  id : int
  title : string
  done : bool

pub struct incident
  id : int
  title : string
  severity : string
  status : string
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

pub struct model
  tasks : list<task>
  draft : string
  next_id : int
  filter_name : string
  notice : string
  route_name : string
  todo_local_tree : list<state_entry>
  lab : workflow_lab

pub fun task_id(item : task) : int
  task/id(item)

pub fun task_title(item : task) : string
  task/title(item)

pub fun task_done(item : task) : bool
  task/done(item)

pub fun model_tasks(item : model) : list<task>
  model/tasks(item)

pub fun model_draft(item : model) : string
  model/draft(item)

pub fun model_next_id(item : model) : int
  model/next_id(item)

pub fun set_next_id(item : model, next_id : int) : model
  item(next_id = next_id)

pub fun model_filter_name(item : model) : string
  model/filter_name(item)

pub fun model_notice(item : model) : string
  model/notice(item)

pub fun model_route_name(item : model) : string
  model/route_name(item)

pub fun model_todo_local_tree(item : model) : list<state_entry>
  model/todo_local_tree(item)

pub fun set_todo_local_tree(item : model, todo_local_tree : list<state_entry>) : model
  item(todo_local_tree = todo_local_tree)

pub fun model_lab(item : model) : workflow_lab
  model/lab(item)

pub fun set_tasks(item : model, tasks : list<task>) : model
  item(tasks = tasks)

pub fun incident_id(item : incident) : int
  incident/id(item)

pub fun incident_title(item : incident) : string
  incident/title(item)

pub fun incident_severity(item : incident) : string
  incident/severity(item)

pub fun incident_status(item : incident) : string
  incident/status(item)

pub fun incident_summary(item : incident) : string
  incident/summary(item)

pub fun incident_server_note(item : incident) : string
  incident/server_note(item)

pub fun incident_updated_by(item : incident) : string
  incident/updated_by(item)

pub fun lab_snapshot_incidents(item : lab_snapshot) : list<incident>
  lab_snapshot/incidents(item)

pub fun lab_snapshot_summary(item : lab_snapshot) : string
  lab_snapshot/summary(item)

pub fun lab_incidents(item : workflow_lab) : list<incident>
  workflow_lab/incidents(item)

pub fun lab_activity_log(item : workflow_lab) : list<string>
  workflow_lab/activity_log(item)

pub fun lab_local_tree(item : workflow_lab) : list<state_entry>
  workflow_lab/local_tree(item)

pub fun lab_sync_status(item : workflow_lab) : string
  workflow_lab/sync_status(item)

pub fun lab_last_sync_label(item : workflow_lab) : string
  workflow_lab/last_sync_label(item)

pub fun normalize_route(route_name : string) : string
  if route_name == "todo" then "todo"
  else if route_name == "lab" then "lab"
  else if route_name == "effects" then "effects"
  else if route_name == "checks" then "checks"
  else "overview"

pub fun task_toggle_id(item : task) : string
  "toggle-" ++ task/id(item).show

pub fun task_remove_id(item : task) : string
  "remove-" ++ task/id(item).show

pub fun task_edit_id(item : task) : string
  "edit-" ++ task_id(item).show

pub fun task_save_id(item : task) : string
  "save-" ++ task_id(item).show

pub fun task_cancel_id(item : task) : string
  "cancel-" ++ task_id(item).show

pub fun task_draft_channel(item : task) : string
  "task-draft-" ++ task_id(item).show

pub fun incident_toggle_payload(item : incident) : string
  "lab-toggle-" ++ incident_id(item).show

pub fun incident_draft_channel(item : incident) : string
  "lab-draft-" ++ incident_id(item).show

pub fun incident_send_payload(item : incident) : string
  "lab-send-" ++ incident_id(item).show

fun incident_state_base(incident_id : int) : string
  "lab/incidents/" ++ incident_id.show

fun incident_expanded_slot(incident_id : int) : state_slot
  named_slot(incident_state_base(incident_id), "expanded")

fun incident_draft_slot(incident_id : int) : state_slot
  named_slot(incident_state_base(incident_id), "draft")

fun incident_expanded(item : workflow_lab, incident_id : int) : <div> bool
  slot_flag(lab_local_tree(item), incident_expanded_slot(incident_id), False)

fun incident_draft(item : workflow_lab, incident_id : int) : <div> string
  slot_text(lab_local_tree(item), incident_draft_slot(incident_id), "")

pub fun has_done_tasks(tasks : list<task>) : <div> bool
  any(tasks, task_done)

pub fun count_all(tasks : list<task>) : <div> int
  length(tasks)

pub fun count_done(tasks : list<task>) : <div> int
  length(filter(tasks, task_done))

fun count_incidents(items : list<incident>) : <div> int
  length(items)

fun count_open_incidents(items : list<incident>) : <div> int
  length(filter(items, fn(item) incident_status(item) != "acked"))

fun count_lines(lines : list<string>) : <div> int
  length(lines)

fun count_non_empty_drafts(item : workflow_lab, incidents : list<incident>) : <div> int
  length(filter(incidents, fn(incident) incident_draft(item, incident_id(incident)) != ""))

pub fun lab_incident_count(item : workflow_lab) : <div> int
  count_incidents(lab_incidents(item))

pub fun lab_open_count(item : workflow_lab) : <div> int
  count_open_incidents(lab_incidents(item))

pub fun lab_draft_count(item : workflow_lab) : <div> int
  count_non_empty_drafts(item, lab_incidents(item))

pub fun lab_activity_count(item : workflow_lab) : <div> int
  count_lines(lab_activity_log(item))

pub fun lab_local_count(item : workflow_lab) : <div> int
  count_entries(lab_local_tree(item))

fun task_visible(item : task) : current_filter bool
  if current_filter == "active" then not(task_done(item))
  else if current_filter == "done" then task_done(item)
  else True

pub fun visible_tasks(tasks : list<task>) : <current_filter,div> list<task>
  filter(tasks, task_visible)

pub fun tasks_for(filter_name : string, tasks : list<task>) : <div> list<task>
  with val current_filter = filter_name
  visible_tasks(tasks)

pub fun find_incident_by_id(target_id : int, items : list<incident>) : <div> maybe<incident>
  find(items, fn(item) target_id == incident_id(item))

pub fun find_task_by_id(target_id : int, tasks : list<task>) : <div> maybe<task>
  find(tasks, fn(item) target_id == task_id(item))

pub fun lab_incident_by_id(item : workflow_lab, target_id : int) : <div> maybe<incident>
  find_incident_by_id(target_id, lab_incidents(item))

pub fun set_notice(item : model, notice : string) : model
  item(notice = notice)

pub fun set_filter(item : model, filter_name : string) : model
  item(filter_name = filter_name, notice = "Primary list switched to `" ++ filter_name ++ "`.")

pub fun set_draft(item : model, draft : string) : model
  item(draft = draft)

pub fun set_lab(item : model, lab : workflow_lab) : model
  item(lab = lab)

pub fun set_route(item : model, route_name : string) : model
  item(route_name = normalize_route(route_name))

// Route changes remain data-only; render-time hooks now decide whether to execute browser effects.
pub fun reduce_click(payload : string, item : model) : <confirm_action,audit,current_operator,wait_ms,fetch_lab_snapshot,post_lab_reply,now_label,div> model
  if payload == "route-overview" then set_route(item, "overview")
  else if payload == "route-todo" then set_route(item, "todo")
  else if payload == "route-lab" then set_route(item, "lab")
  else if payload == "route-effects" then set_route(item, "effects")
  else if payload == "route-checks" then set_route(item, "checks")
  else set_notice(item, "Unknown action: " ++ payload)

pub fun reduce_input(channel : string, value : string, item : model) : <div> model
  set_notice(item, "Unhandled input channel: " ++ channel ++ " = " ++ value)
