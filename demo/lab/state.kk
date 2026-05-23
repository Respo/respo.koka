module demo/lab/state

import demo/model
import explore/react/state

pub struct incident_local_state(expanded : bool, draft : string)
pub alias lab_local_effect = <local_state_write,hook_state,hook_effects,div>

fun incident_component_key(incident_id : int) : string
  incident_id.show

pub fun lab_incident_expanded(tree : list<state_entry>, incident_id : int) : <div> bool
  read_component_indexed_state(tree, "incidents", incident_component_key(incident_id), 0, flag_state_codec, False)

pub fun lab_incident_draft(tree : list<state_entry>, incident_id : int) : <div> string
  read_component_indexed_state(tree, "incidents", incident_component_key(incident_id), 1, text_state_codec, "")

pub fun finalize_incident_reply_tree(tree : list<state_entry>, incident_id : int) : <div> list<state_entry>
  clear_component_indexed_state(
    assoc_component_indexed_state(tree, "incidents", incident_component_key(incident_id), 0, flag_state_codec, True),
    "incidents",
    incident_component_key(incident_id),
    1)

pub fun commit_lab_tree(owner : model, action : () -> <lab_local_effect,local_state_read,hook_scope|e> model) : <div|e> model
  val (next_model, next_tree, _pending_effect) = run_local_state(owner.app_local_tree, action)
  next_model(app_local_tree = next_tree)

pub fun set_local_lab_draft(owner : model, incident_id : int, draft : string) : <lab_local_effect> model
  if draft == "" then
    clear_component_indexed_state_effect("incidents", incident_component_key(incident_id), 1)
  else
    set_component_indexed_state("incidents", incident_component_key(incident_id), 1, text_state_codec, draft)
  owner

pub fun toggle_local_lab_expanded(owner : model, incident_id : int) : <lab_local_effect> model
  set_component_indexed_state("incidents", incident_component_key(incident_id), 0, flag_state_codec, not(lab_incident_expanded(owner.app_local_tree, incident_id)))
  owner