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

pub struct task(id : int, title : string, done : bool)
pub struct incident(id : int, title : string, severity : string, status : string, summary : string, server_note : string, updated_by : string)
pub struct lab_snapshot(incidents : list<incident>, summary : string)
pub struct workflow_lab(incidents : list<incident>, activity_log : list<string>, local_tree : list<state_entry>, sync_status : string, last_sync_label : string)
pub struct model(tasks : list<task>, draft : string, next_id : int, filter_name : string, notice : string, route_name : string, todo_local_tree : list<state_entry>, lab : workflow_lab)

pub fun task_id(item : task) : int
  match item
    Task(id, _, _) -> id

pub fun task_title(item : task) : string
  match item
    Task(_, title, _) -> title

pub fun task_done(item : task) : bool
  match item
    Task(_, _, done) -> done

pub fun model_tasks(item : model) : list<task>
  match item
    Model(tasks, _, _, _, _, _, _, _) -> tasks

pub fun model_draft(item : model) : string
  match item
    Model(_, draft, _, _, _, _, _, _) -> draft

pub fun model_next_id(item : model) : int
  match item
    Model(_, _, next_id, _, _, _, _, _) -> next_id

pub fun set_next_id(item : model, next_id : int) : model
  Model(model_tasks(item), model_draft(item), next_id, model_filter_name(item), model_notice(item), model_route_name(item), model_todo_local_tree(item), model_lab(item))

pub fun model_filter_name(item : model) : string
  match item
    Model(_, _, _, filter_name, _, _, _, _) -> filter_name

pub fun model_notice(item : model) : string
  match item
    Model(_, _, _, _, notice, _, _, _) -> notice

pub fun model_route_name(item : model) : string
  match item
    Model(_, _, _, _, _, route_name, _, _) -> route_name

pub fun model_todo_local_tree(item : model) : list<state_entry>
  match item
    Model(_, _, _, _, _, _, todo_local_tree, _) -> todo_local_tree

pub fun set_todo_local_tree(item : model, todo_local_tree : list<state_entry>) : model
  Model(model_tasks(item), model_draft(item), model_next_id(item), model_filter_name(item), model_notice(item), model_route_name(item), todo_local_tree, model_lab(item))

pub fun model_lab(item : model) : workflow_lab
  match item
    Model(_, _, _, _, _, _, _, lab) -> lab

pub fun set_tasks(item : model, tasks : list<task>) : model
  Model(tasks, model_draft(item), model_next_id(item), model_filter_name(item), model_notice(item), model_route_name(item), model_todo_local_tree(item), model_lab(item))

pub fun incident_id(item : incident) : int
  match item
    Incident(id, _, _, _, _, _, _) -> id

pub fun incident_title(item : incident) : string
  match item
    Incident(_, title, _, _, _, _, _) -> title

pub fun incident_severity(item : incident) : string
  match item
    Incident(_, _, severity, _, _, _, _) -> severity

pub fun incident_status(item : incident) : string
  match item
    Incident(_, _, _, status, _, _, _) -> status

pub fun incident_summary(item : incident) : string
  match item
    Incident(_, _, _, _, summary, _, _) -> summary

pub fun incident_server_note(item : incident) : string
  match item
    Incident(_, _, _, _, _, server_note, _) -> server_note

pub fun incident_updated_by(item : incident) : string
  match item
    Incident(_, _, _, _, _, _, updated_by) -> updated_by

pub fun lab_snapshot_incidents(item : lab_snapshot) : list<incident>
  match item
    Lab_snapshot(incidents, _) -> incidents

pub fun lab_snapshot_summary(item : lab_snapshot) : string
  match item
    Lab_snapshot(_, summary) -> summary

pub fun lab_incidents(item : workflow_lab) : list<incident>
  match item
    Workflow_lab(incidents, _, _, _, _) -> incidents

pub fun lab_activity_log(item : workflow_lab) : list<string>
  match item
    Workflow_lab(_, activity_log, _, _, _) -> activity_log

pub fun lab_local_tree(item : workflow_lab) : list<state_entry>
  match item
    Workflow_lab(_, _, local_tree, _, _) -> local_tree

pub fun lab_sync_status(item : workflow_lab) : string
  match item
    Workflow_lab(_, _, _, sync_status, _) -> sync_status

pub fun lab_last_sync_label(item : workflow_lab) : string
  match item
    Workflow_lab(_, _, _, _, last_sync_label) -> last_sync_label

pub fun normalize_route(route_name : string) : string
  if route_name == "todo" then "todo"
  else if route_name == "lab" then "lab"
  else if route_name == "effects" then "effects"
  else if route_name == "checks" then "checks"
  else "overview"

pub fun task_toggle_id(item : task) : string
  "toggle-" ++ task_id(item).show

pub fun task_remove_id(item : task) : string
  "remove-" ++ task_id(item).show

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
  match tasks
    Nil -> False
    Cons(item, rest) -> if task_done(item) then True else has_done_tasks(rest)

pub fun count_all(tasks : list<task>) : <div> int
  match tasks
    Nil -> 0
    Cons(_, rest) -> 1 + count_all(rest)

pub fun count_done(tasks : list<task>) : <div> int
  match tasks
    Nil -> 0
    Cons(item, rest) -> (if task_done(item) then 1 else 0) + count_done(rest)

fun count_incidents(items : list<incident>) : <div> int
  match items
    Nil -> 0
    Cons(_, rest) -> 1 + count_incidents(rest)

fun count_open_incidents(items : list<incident>) : <div> int
  match items
    Nil -> 0
    Cons(item, rest) -> (if incident_status(item) == "acked" then 0 else 1) + count_open_incidents(rest)

fun count_lines(lines : list<string>) : <div> int
  match lines
    Nil -> 0
    Cons(_, rest) -> 1 + count_lines(rest)

fun count_non_empty_drafts(item : workflow_lab, incidents : list<incident>) : <div> int
  match incidents
    Nil -> 0
    Cons(incident, rest) -> (if incident_draft(item, incident_id(incident)) == "" then 0 else 1) + count_non_empty_drafts(item, rest)

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
  match tasks
    Nil -> Nil
    Cons(item, rest) ->
      val tail = visible_tasks(rest)
      if task_visible(item) then Cons(item, tail) else tail

pub fun tasks_for(filter_name : string, tasks : list<task>) : <div> list<task>
  with val current_filter = filter_name
  visible_tasks(tasks)

pub fun find_incident_by_id(target_id : int, items : list<incident>) : <div> maybe<incident>
  match items
    Nil -> Nothing
    Cons(item, rest) -> if target_id == incident_id(item) then Just(item) else find_incident_by_id(target_id, rest)

pub fun find_task_by_id(target_id : int, tasks : list<task>) : <div> maybe<task>
  match tasks
    Nil -> Nothing
    Cons(item, rest) -> if target_id == task_id(item) then Just(item) else find_task_by_id(target_id, rest)

pub fun lab_incident_by_id(item : workflow_lab, target_id : int) : <div> maybe<incident>
  find_incident_by_id(target_id, lab_incidents(item))

pub fun set_notice(item : model, notice : string) : model
  Model(model_tasks(item), model_draft(item), model_next_id(item), model_filter_name(item), notice, model_route_name(item), model_todo_local_tree(item), model_lab(item))

pub fun set_filter(item : model, filter_name : string) : model
  Model(model_tasks(item), model_draft(item), model_next_id(item), filter_name, "Primary list switched to `" ++ filter_name ++ "`.", model_route_name(item), model_todo_local_tree(item), model_lab(item))

pub fun set_draft(item : model, draft : string) : model
  Model(model_tasks(item), draft, model_next_id(item), model_filter_name(item), model_notice(item), model_route_name(item), model_todo_local_tree(item), model_lab(item))

pub fun set_lab(item : model, lab : workflow_lab) : model
  Model(model_tasks(item), model_draft(item), model_next_id(item), model_filter_name(item), model_notice(item), model_route_name(item), model_todo_local_tree(item), lab)

pub fun set_route(item : model, route_name : string) : model
  Model(model_tasks(item), model_draft(item), model_next_id(item), model_filter_name(item), model_notice(item), normalize_route(route_name), model_todo_local_tree(item), model_lab(item))

fun append_tasks(tasks : list<task>, item : task) : <div> list<task>
  match tasks
    Nil -> [item]
    Cons(head, rest) -> Cons(head, append_tasks(rest, item))

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

pub fun has_toggle(payload : string, tasks : list<task>) : <div> bool
  match tasks
    Nil -> False
    Cons(item, rest) -> if payload == task_toggle_id(item) then True else has_toggle(payload, rest)

pub fun has_remove(payload : string, tasks : list<task>) : <div> bool
  match tasks
    Nil -> False
    Cons(item, rest) -> if payload == task_remove_id(item) then True else has_remove(payload, rest)
