module demo/lab/workflow

import demo/model
import demo/lab/state
import respo/state

fun append_lines(lines : list<string>, value : string) : <div> list<string>
  match lines
    Nil -> [value]
    Cons(head, rest) -> Cons(head, append_lines(rest, value))

fun update_incident_reply(items : list<incident>, target_id : int, message : string, updated_by : string) : <div> list<incident>
  match items
    Nil -> Nil
    Cons(item, rest) ->
      val next_rest = update_incident_reply(rest, target_id, message, updated_by)
      if incident_id(item) == target_id then
        Cons(Incident(incident_id(item), incident_title(item), incident_severity(item), "acked", incident_summary(item), message, updated_by), next_rest)
      else
        Cons(item, next_rest)

pub fun load_snapshot(item : model) : <fetch_lab_snapshot,now_label,audit,div> model
  audit("Loaded workflow lab snapshot from a mocked server handler.")
  val snapshot = fetch_lab_snapshot()
  val stamp = now_label()
  val lab = model_lab(item)
  val next_lab = Workflow_lab(lab_snapshot_incidents(snapshot), append_lines(lab_activity_log(lab), "[" ++ stamp ++ "] " ++ lab_snapshot_summary(snapshot)), lab_local_tree(lab), "loaded", stamp)
  set_notice(set_lab(item, next_lab), "Workflow lab loaded mock server data.")

pub fun perform_sync(item : model) : <wait_ms,fetch_lab_snapshot,now_label,audit,div> model
  audit("Started staged sync for workflow lab.")
  wait_ms(30)
  val snapshot = fetch_lab_snapshot()
  wait_ms(90)
  val stamp = now_label()
  val lab = model_lab(item)
  val next_lab = Workflow_lab(lab_snapshot_incidents(snapshot), append_lines(lab_activity_log(lab), "[" ++ stamp ++ "] sync: " ++ lab_snapshot_summary(snapshot)), lab_local_tree(lab), "synced", stamp)
  set_notice(set_lab(item, next_lab), "Workflow lab sync finished through algebraic effects.")

pub fun send_reply(item : model, incident_id : int) : <wait_ms,post_lab_reply,now_label,audit,current_operator,div> model
  val lab = model_lab(item)
  val draft = lab_incident_draft(lab, incident_id)
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
        val next_tree = clear_slot_state(assoc_slot_flag(lab_local_tree(lab), incident_expanded_slot(incident_id), True), incident_draft_slot(incident_id))
        val next_incidents = update_incident_reply(lab_incidents(lab), incident_id, draft, operator ++ " @ " ++ stamp)
        val next_logs = append_lines(lab_activity_log(lab), "[" ++ stamp ++ "] " ++ server_reply)
        val next_lab = Workflow_lab(next_incidents, next_logs, next_tree, "reply-sent", stamp)
        set_notice(set_lab(item, next_lab), "Workflow lab reply sent with mocked server effect.")
      }