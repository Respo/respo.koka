module demo/lab/state

import demo/model
import respo/state

pub fun incident_hook_scope(incident_id : int) : string
  "lab/incidents/" ++ incident_id.show

pub fun incident_expanded_slot(incident_id : int) : state_slot
  hook_state_slot(incident_hook_scope(incident_id), 0)

pub fun incident_draft_slot(incident_id : int) : state_slot
  hook_state_slot(incident_hook_scope(incident_id), 1)

pub fun lab_incident_expanded(item : workflow_lab, incident_id : int) : <div> bool
  slot_flag(item.local_tree, incident_expanded_slot(incident_id), False)

pub fun lab_incident_draft(item : workflow_lab, incident_id : int) : <div> string
  slot_text(item.local_tree, incident_draft_slot(incident_id), "")

pub fun set_lab_local_tree(owner : model, next_tree : list<state_entry>) : model
  val lab = owner.lab
  set_lab(owner, lab(local_tree = next_tree))

pub fun commit_lab_tree(owner : model, action : () -> <use_named_state,set_named_state,clear_local_state,use_named_effect,push_hook_scope,pop_hook_scope,use_state,use_state_pair,use_effect,div|e> model) : <div|e> model
  val (next_model, next_tree, _pending_effect) = run_local_state(owner.lab.local_tree, action)
  set_lab_local_tree(next_model, next_tree)

pub fun set_local_lab_draft(owner : model, incident_id : int, draft : string) : <use_named_state,set_named_state,clear_local_state,div> model
  val (_current_draft, set_draft) = use_named_state_pair(incident_draft_slot(incident_id), text_state_codec, "")
  if draft == "" then
    clear_slot(incident_draft_slot(incident_id))
  else
    set_draft(draft)
  owner

pub fun toggle_local_lab_expanded(owner : model, incident_id : int) : <use_named_state,set_named_state,div> model
  val (expanded, set_expanded) = use_named_state_pair(incident_expanded_slot(incident_id), flag_state_codec, False)
  set_expanded(not(expanded))
  owner