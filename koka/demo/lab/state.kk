module demo/lab/state

import demo/model
import respo/state

fun incident_state_base(incident_id : int) : string
  "lab/incidents/" ++ incident_id.show

pub fun incident_expanded_slot(incident_id : int) : state_slot
  named_slot(incident_state_base(incident_id), "expanded")

pub fun incident_draft_slot(incident_id : int) : state_slot
  named_slot(incident_state_base(incident_id), "draft")

pub fun lab_incident_expanded(item : workflow_lab, incident_id : int) : <div> bool
  slot_flag(lab_local_tree(item), incident_expanded_slot(incident_id), False)

pub fun lab_incident_draft(item : workflow_lab, incident_id : int) : <div> string
  slot_text(lab_local_tree(item), incident_draft_slot(incident_id), "")

pub fun set_lab_local_tree(owner : model, next_tree : list<state_entry>) : model
  val lab = model_lab(owner)
  set_lab(owner, Workflow_lab(lab_incidents(lab), lab_activity_log(lab), next_tree, lab_sync_status(lab), lab_last_sync_label(lab)))

pub fun commit_lab_tree(owner : model, action : () -> <use_state,set_state,clear_local_state,use_effect,div|e> model) : <div|e> model
  val (next_model, next_tree, _pending_effect) = run_local_state(lab_local_tree(model_lab(owner)), action)
  set_lab_local_tree(next_model, next_tree)

pub fun set_local_lab_draft(owner : model, incident_id : int, draft : string) : <set_state,clear_local_state,div> model
  if draft == "" then
    clear_slot(incident_draft_slot(incident_id))
  else
    set_state(incident_draft_slot(incident_id), text_state_codec, draft)
  owner

pub fun toggle_local_lab_expanded(owner : model, incident_id : int) : <use_state,set_state,div> model
  val expanded = use_state(incident_expanded_slot(incident_id), flag_state_codec, False)
  set_state(incident_expanded_slot(incident_id), flag_state_codec, not(expanded))
  owner