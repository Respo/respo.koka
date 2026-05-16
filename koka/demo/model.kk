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

pub fun model_lab(item : model) : workflow_lab
  match item
    Model(_, _, _, _, _, _, _, lab) -> lab

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

pub fun mock_lab_snapshot() : lab_snapshot
  Lab_snapshot(
    [
      Incident(101, "Edge cache serving stale auth bundle", "p1", "firing", "Login JS bundle is 17 minutes behind origin in two POPs.", "Origin checksum mismatch observed on 4 probes.", "mock-edge-bot"),
      Incident(102, "Worker queue saturation", "p2", "investigating", "Batch replay queue is at 86% depth after the latest deploy.", "Autoscaler added one node but backlog is still trending up.", "ops-sim"),
      Incident(103, "Image thumbnail cold start", "p3", "acked", "New region takes 1.3s to warm the thumbnail worker.", "Tracked for the next runtime image cut.", "ops-sim"),
    ],
    "Mock server returned 3 incidents for the workflow lab.")

pub fun mock_lab_reply(incident_id : int, message : string) : string
  "Mock server accepted reply for #" ++ incident_id.show ++ ": " ++ message

fun initial_lab() : workflow_lab
  Workflow_lab(
    lab_snapshot_incidents(mock_lab_snapshot()),
    ["[boot] Seeded workflow lab with a deterministic snapshot."],
    Nil,
    "seeded",
    "boot")

pub fun initial_model() : model
  Model(
    [
      Task(1, "Map React-like updates onto a Koka store", True),
      Task(2, "Keep diff + patch inside Koka", False),
      Task(3, "Use algebraic effects for destructive flows", False),
    ],
    "",
    4,
    "all",
    "Ready: Koka owns components, state, and diff/patch.",
    "overview",
    Nil,
    initial_lab())

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

fun incident_expanded_path(incident_id : int) : string
  "lab/incidents/" ++ incident_id.show ++ "/expanded"

fun incident_draft_path(incident_id : int) : string
  "lab/incidents/" ++ incident_id.show ++ "/draft"

fun task_editing_path(task_id : int) : string
  "todo/tasks/" ++ task_id.show ++ "/editing"

fun task_draft_path(task_id : int) : string
  "todo/tasks/" ++ task_id.show ++ "/draft"

pub fun task_is_editing(item : model, task_id : int) : <div> bool
  state_flag(model_todo_local_tree(item), task_editing_path(task_id), False)

pub fun task_edit_draft(item : model, task_id : int, fallback : string) : <div> string
  state_text(model_todo_local_tree(item), task_draft_path(task_id), fallback)

pub fun incident_expanded(item : workflow_lab, incident_id : int) : <div> bool
  state_flag(lab_local_tree(item), incident_expanded_path(incident_id), False)

pub fun incident_draft(item : workflow_lab, incident_id : int) : <div> string
  state_text(lab_local_tree(item), incident_draft_path(incident_id), "")

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

fun append_lines(lines : list<string>, value : string) : <div> list<string>
  match lines
    Nil -> [value]
    Cons(head, rest) -> Cons(head, append_lines(rest, value))

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

fun update_incident_reply(items : list<incident>, target_id : int, message : string, updated_by : string) : <div> list<incident>
  match items
    Nil -> Nil
    Cons(item, rest) ->
      val next_rest = update_incident_reply(rest, target_id, message, updated_by)
      if incident_id(item) == target_id then
        Cons(Incident(incident_id(item), incident_title(item), incident_severity(item), "acked", incident_summary(item), message, updated_by), next_rest)
      else
        Cons(item, next_rest)

fun rename_task(items : list<task>, target_id : int, title : string) : <div> list<task>
  match items
    Nil -> Nil
    Cons(item, rest) ->
      val next_rest = rename_task(rest, target_id, title)
      if task_id(item) == target_id then
        Cons(Task(task_id(item), title, task_done(item)), next_rest)
      else
        Cons(item, next_rest)

fun set_todo_local_tree(item : model, todo_local_tree : list<state_entry>) : model
  Model(model_tasks(item), model_draft(item), model_next_id(item), model_filter_name(item), model_notice(item), model_route_name(item), todo_local_tree, model_lab(item))

fun clear_task_local_state(tree : list<state_entry>, task_id : int) : <div> list<state_entry>
  clear_state(clear_state(tree, task_editing_path(task_id)), task_draft_path(task_id))

fun clear_removed_task_state(payload : string, tree : list<state_entry>, tasks : list<task>) : <div> list<state_entry>
  match tasks
    Nil -> tree
    Cons(item, rest) ->
      if payload == task_remove_id(item) then
        clear_task_local_state(tree, task_id(item))
      else
        clear_removed_task_state(payload, tree, rest)

fun clear_completed_task_state(tree : list<state_entry>, tasks : list<task>) : <div> list<state_entry>
  match tasks
    Nil -> tree
    Cons(item, rest) ->
      val next_tree = clear_completed_task_state(tree, rest)
      if task_done(item) then clear_task_local_state(next_tree, task_id(item)) else next_tree

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

pub fun toggle_lab_expanded(item : model, incident_id : int) : <div> model
  val lab = model_lab(item)
  val next_tree = assoc_flag(lab_local_tree(lab), incident_expanded_path(incident_id), not(incident_expanded(lab, incident_id)))
  set_lab(item, Workflow_lab(lab_incidents(lab), lab_activity_log(lab), next_tree, lab_sync_status(lab), lab_last_sync_label(lab)))

pub fun set_lab_draft(item : model, incident_id : int, draft : string) : <div> model
  val lab = model_lab(item)
  val next_tree = if draft == "" then clear_state(lab_local_tree(lab), incident_draft_path(incident_id)) else assoc_text(lab_local_tree(lab), incident_draft_path(incident_id), draft)
  set_lab(item, Workflow_lab(lab_incidents(lab), lab_activity_log(lab), next_tree, lab_sync_status(lab), lab_last_sync_label(lab)))

fun append_tasks(tasks : list<task>, item : task) : <div> list<task>
  match tasks
    Nil -> [item]
    Cons(head, rest) -> Cons(head, append_tasks(rest, item))

// Keep addition pure and effect-aware: the caller decides how to interpret audit logs.
// Focus intent is returned as data so it composes cleanly with the evidence-passing runtime.
pub fun add_task(item : model) : <audit,div> (model, maybe<string>)
  if model_draft(item) == "" then
    (set_notice(item, "Draft is empty. Type something before adding."), Nothing)
  else
    audit("Added task: " ++ model_draft(item))
    (Model(
      append_tasks(model_tasks(item), Task(model_next_id(item), model_draft(item), False)),
      "",
      model_next_id(item) + 1,
      model_filter_name(item),
      "Added a new task from the Koka store.",
      model_route_name(item),
      model_todo_local_tree(item),
      model_lab(item)), Just("draft"))

fun toggle_tasks(payload : string, tasks : list<task>) : <div> list<task>
  match tasks
    Nil -> Nil
    Cons(item, rest) ->
      val next_rest = toggle_tasks(payload, rest)
      if payload == task_toggle_id(item) then Cons(Task(task_id(item), task_title(item), not(task_done(item))), next_rest) else Cons(item, next_rest)

fun find_by_remove(payload : string, tasks : list<task>) : <div> maybe<task>
  match tasks
    Nil -> Nothing
    Cons(item, rest) -> if payload == task_remove_id(item) then Just(item) else find_by_remove(payload, rest)

fun remove_tasks(payload : string, tasks : list<task>) : <div> list<task>
  match tasks
    Nil -> Nil
    Cons(item, rest) -> if payload == task_remove_id(item) then rest else Cons(item, remove_tasks(payload, rest))

fun clear_completed(tasks : list<task>) : <div> list<task>
  match tasks
    Nil -> Nil
    Cons(item, rest) -> if task_done(item) then clear_completed(rest) else Cons(item, clear_completed(rest))

pub fun handle_toggle(item : model, payload : string) : <audit,div> model
  audit("Toggled task state from the Koka reducer.")
  Model(toggle_tasks(payload, model_tasks(item)), model_draft(item), model_next_id(item), model_filter_name(item), "Toggled a task.", model_route_name(item), model_todo_local_tree(item), model_lab(item))

pub fun handle_remove(item : model, payload : string) : <confirm_action,audit,div> model
  match find_by_remove(payload, model_tasks(item))
    Nothing -> set_notice(item, "Task not found for removal.")
    Just(found) ->
      if confirm_action("Remove `" ++ task_title(found) ++ "`?") then
        audit("Removed task after confirmation: " ++ task_title(found))
        Model(remove_tasks(payload, model_tasks(item)), model_draft(item), model_next_id(item), model_filter_name(item), "Task removed after confirm effect.", model_route_name(item), clear_removed_task_state(payload, model_todo_local_tree(item), model_tasks(item)), model_lab(item))
      else
        set_notice(item, "Removal cancelled by confirm effect.")

pub fun handle_clear_completed(item : model) : <confirm_action,audit,div> model
  if not(has_done_tasks(model_tasks(item))) then
    set_notice(item, "There are no completed tasks to clear.")
  else if confirm_action("Clear every completed task?") then
    audit("Cleared completed tasks.")
    Model(clear_completed(model_tasks(item)), model_draft(item), model_next_id(item), model_filter_name(item), "Completed tasks cleared after confirm effect.", model_route_name(item), clear_completed_task_state(model_todo_local_tree(item), model_tasks(item)), model_lab(item))
  else
    set_notice(item, "Clear completed cancelled.")

pub fun start_task_edit(item : model, task_id : int) : <audit,div> (model, maybe<string>)
  match find_task_by_id(task_id, model_tasks(item))
    Nothing -> (set_notice(item, "Task not found for local editing."), Nothing)
    Just(found) -> {
      audit("Opened local edit state for task #" ++ task_id.show)
      val next_tree = assoc_text(assoc_flag(model_todo_local_tree(item), task_editing_path(task_id), True), task_draft_path(task_id), task_title(found))
      (set_notice(set_todo_local_tree(item, next_tree), "Editing task locally before committing the title."), Just(task_draft_channel(found)))
    }

pub fun set_task_edit_draft(item : model, task_id : int, draft : string) : <div> model
  set_todo_local_tree(item, assoc_text(model_todo_local_tree(item), task_draft_path(task_id), draft))

pub fun cancel_task_edit(item : model, task_id : int) : <div> model
  set_notice(set_todo_local_tree(item, clear_task_local_state(model_todo_local_tree(item), task_id)), "Cancelled local task edit.")

pub fun save_task_edit(item : model, task_id : int) : <audit,div> model
  match find_task_by_id(task_id, model_tasks(item))
    Nothing -> set_notice(item, "Task not found while saving the local edit.")
    Just(found) -> {
      val draft = task_edit_draft(item, task_id, task_title(found))
      if draft == "" then
        set_notice(item, "Task title cannot be empty.")
      else {
        audit("Saved local task edit for #" ++ task_id.show)
        val next_item = set_todo_local_tree(
          Model(rename_task(model_tasks(item), task_id, draft), model_draft(item), model_next_id(item), model_filter_name(item), model_notice(item), model_route_name(item), model_todo_local_tree(item), model_lab(item)),
          clear_task_local_state(model_todo_local_tree(item), task_id))
        set_notice(next_item, "Saved task title from local state.")
      }
    }

pub fun load_lab_snapshot(item : model) : <fetch_lab_snapshot,now_label,audit,div> model
  audit("Loaded workflow lab snapshot from a mocked server handler.")
  val snapshot = fetch_lab_snapshot()
  val stamp = now_label()
  val lab = model_lab(item)
  val next_lab = Workflow_lab(lab_snapshot_incidents(snapshot), append_lines(lab_activity_log(lab), "[" ++ stamp ++ "] " ++ lab_snapshot_summary(snapshot)), lab_local_tree(lab), "loaded", stamp)
  set_notice(set_lab(item, next_lab), "Workflow lab loaded mock server data.")

pub fun perform_lab_sync(item : model) : <wait_ms,fetch_lab_snapshot,now_label,audit,div> model
  audit("Started staged sync for workflow lab.")
  wait_ms(30)
  val snapshot = fetch_lab_snapshot()
  wait_ms(90)
  val stamp = now_label()
  val lab = model_lab(item)
  val next_lab = Workflow_lab(lab_snapshot_incidents(snapshot), append_lines(lab_activity_log(lab), "[" ++ stamp ++ "] sync: " ++ lab_snapshot_summary(snapshot)), lab_local_tree(lab), "synced", stamp)
  set_notice(set_lab(item, next_lab), "Workflow lab sync finished through algebraic effects.")

pub fun send_lab_reply(item : model, incident_id : int) : <wait_ms,post_lab_reply,now_label,audit,current_operator,div> model
  val lab = model_lab(item)
  val draft = incident_draft(lab, incident_id)
  if draft == "" then
    set_notice(item, "Draft is empty for this incident card.")
  else
    match lab_incident_by_id(lab, incident_id)
      Nothing -> set_notice(item, "Incident not found in workflow lab.")
      Just(_found) -> {
        audit("Sending workflow lab reply for incident #" ++ incident_id.show)
        wait_ms(40)
        val server_reply = post_lab_reply(incident_id, draft)
        wait_ms(20)
        val stamp = now_label()
        val operator = current_operator
        val next_tree = clear_state(assoc_flag(lab_local_tree(lab), incident_expanded_path(incident_id), True), incident_draft_path(incident_id))
        val next_incidents = update_incident_reply(lab_incidents(lab), incident_id, draft, operator ++ " @ " ++ stamp)
        val next_logs = append_lines(lab_activity_log(lab), "[" ++ stamp ++ "] " ++ server_reply)
        val next_lab = Workflow_lab(next_incidents, next_logs, next_tree, "reply-sent", stamp)
        set_notice(set_lab(item, next_lab), "Workflow lab reply sent with mocked server effect.")
      }

fun find_lab_draft_channel(channel : string, items : list<incident>) : <div> maybe<int>
  match items
    Nil -> Nothing
    Cons(item, rest) -> if channel == incident_draft_channel(item) then Just(incident_id(item)) else find_lab_draft_channel(channel, rest)

fun find_task_draft_channel(channel : string, tasks : list<task>) : <div> maybe<int>
  match tasks
    Nil -> Nothing
    Cons(item, rest) -> if channel == task_draft_channel(item) then Just(task_id(item)) else find_task_draft_channel(channel, rest)

fun has_lab_toggle(payload : string, items : list<incident>) : <div> bool
  match items
    Nil -> False
    Cons(item, rest) -> if payload == incident_toggle_payload(item) then True else has_lab_toggle(payload, rest)

fun has_lab_send(payload : string, items : list<incident>) : <div> bool
  match items
    Nil -> False
    Cons(item, rest) -> if payload == incident_send_payload(item) then True else has_lab_send(payload, rest)

fun has_edit(payload : string, tasks : list<task>) : <div> bool
  match tasks
    Nil -> False
    Cons(item, rest) -> if payload == task_edit_id(item) then True else has_edit(payload, rest)

fun has_save(payload : string, tasks : list<task>) : <div> bool
  match tasks
    Nil -> False
    Cons(item, rest) -> if payload == task_save_id(item) then True else has_save(payload, rest)

fun has_cancel(payload : string, tasks : list<task>) : <div> bool
  match tasks
    Nil -> False
    Cons(item, rest) -> if payload == task_cancel_id(item) then True else has_cancel(payload, rest)

fun incident_id_from_toggle(payload : string, items : list<incident>) : <div> maybe<int>
  match items
    Nil -> Nothing
    Cons(item, rest) -> if payload == incident_toggle_payload(item) then Just(incident_id(item)) else incident_id_from_toggle(payload, rest)

fun incident_id_from_send(payload : string, items : list<incident>) : <div> maybe<int>
  match items
    Nil -> Nothing
    Cons(item, rest) -> if payload == incident_send_payload(item) then Just(incident_id(item)) else incident_id_from_send(payload, rest)

fun task_id_from_edit(payload : string, tasks : list<task>) : <div> maybe<int>
  match tasks
    Nil -> Nothing
    Cons(item, rest) -> if payload == task_edit_id(item) then Just(task_id(item)) else task_id_from_edit(payload, rest)

fun task_id_from_save(payload : string, tasks : list<task>) : <div> maybe<int>
  match tasks
    Nil -> Nothing
    Cons(item, rest) -> if payload == task_save_id(item) then Just(task_id(item)) else task_id_from_save(payload, rest)

fun task_id_from_cancel(payload : string, tasks : list<task>) : <div> maybe<int>
  match tasks
    Nil -> Nothing
    Cons(item, rest) -> if payload == task_cancel_id(item) then Just(task_id(item)) else task_id_from_cancel(payload, rest)

// The UI forwards semantic actions here; effects stay explicit and easy to test.
// add_task and start_task_edit return (model, maybe<string>) so focus intent flows as data.
pub fun reduce_click(payload : string, item : model) : <confirm_action,audit,current_operator,wait_ms,fetch_lab_snapshot,post_lab_reply,now_label,div> (model, maybe<string>)
  if payload == "route-overview" then (set_route(item, "overview"), Nothing)
  else if payload == "route-todo" then (set_route(item, "todo"), Nothing)
  else if payload == "route-lab" then (set_route(item, "lab"), Nothing)
  else if payload == "route-effects" then (set_route(item, "effects"), Nothing)
  else if payload == "route-checks" then (set_route(item, "checks"), Nothing)
  else if payload == "add-task" then add_task(item)
  else if payload == "lab-load" then (load_lab_snapshot(item), Nothing)
  else if payload == "lab-sync" then (perform_lab_sync(item), Nothing)
  else if payload == "set-filter-all" then (set_filter(item, "all"), Nothing)
  else if payload == "set-filter-active" then (set_filter(item, "active"), Nothing)
  else if payload == "set-filter-done" then (set_filter(item, "done"), Nothing)
  else if has_edit(payload, model_tasks(item)) then
    match task_id_from_edit(payload, model_tasks(item))
      Just(task_id) -> start_task_edit(item, task_id)
      Nothing -> (set_notice(item, "Task edit target was missing."), Nothing)
  else if has_save(payload, model_tasks(item)) then
    match task_id_from_save(payload, model_tasks(item))
      Just(task_id) -> (save_task_edit(item, task_id), Nothing)
      Nothing -> (set_notice(item, "Task save target was missing."), Nothing)
  else if has_cancel(payload, model_tasks(item)) then
    match task_id_from_cancel(payload, model_tasks(item))
      Just(task_id) -> (cancel_task_edit(item, task_id), Nothing)
      Nothing -> (set_notice(item, "Task cancel target was missing."), Nothing)
  else if payload == "clear-completed" then (handle_clear_completed(item), Nothing)
  else if has_toggle(payload, model_tasks(item)) then (handle_toggle(item, payload), Nothing)
  else if has_remove(payload, model_tasks(item)) then (handle_remove(item, payload), Nothing)
  else if has_lab_toggle(payload, lab_incidents(model_lab(item))) then
    match incident_id_from_toggle(payload, lab_incidents(model_lab(item)))
      Just(incident_id) -> (toggle_lab_expanded(item, incident_id), Nothing)
      Nothing -> (set_notice(item, "Workflow lab toggle target was missing."), Nothing)
  else if has_lab_send(payload, lab_incidents(model_lab(item))) then
    match incident_id_from_send(payload, lab_incidents(model_lab(item)))
      Just(incident_id) -> (send_lab_reply(item, incident_id), Nothing)
      Nothing -> (set_notice(item, "Workflow lab send target was missing."), Nothing)
  else (set_notice(item, "Unknown action: " ++ payload), Nothing)

pub fun reduce_input(channel : string, value : string, item : model) : <div> model
  if channel == "draft" then
    set_draft(item, value)
  else
    match find_task_draft_channel(channel, model_tasks(item))
      Just(task_id) -> set_task_edit_draft(item, task_id, value)
      Nothing ->
        match find_lab_draft_channel(channel, lab_incidents(model_lab(item)))
          Just(incident_id) -> set_lab_draft(item, incident_id, value)
          Nothing -> set_notice(item, "Unhandled input channel: " ++ channel)

pub fun has_toggle(payload : string, tasks : list<task>) : <div> bool
  match tasks
    Nil -> False
    Cons(item, rest) -> if payload == task_toggle_id(item) then True else has_toggle(payload, rest)

pub fun has_remove(payload : string, tasks : list<task>) : <div> bool
  match tasks
    Nil -> False
    Cons(item, rest) -> if payload == task_remove_id(item) then True else has_remove(payload, rest)
