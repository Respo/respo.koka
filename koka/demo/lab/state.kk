module demo/lab/state

import demo/model
import respo/state

pub struct incident_local_state(expanded : bool, draft : string)
pub alias lab_local_effect = <set_named_state,clear_local_state,use_state,use_state_pair,use_effect,div>

fun incident_component_key(incident_id : int) : string
  incident_id.show

pub fun lab_incident_expanded(tree : list<state_entry>, incident_id : int) : <div> bool
  read_component_named_state(tree, "incidents", incident_component_key(incident_id), "expanded", flag_state_codec, False)

pub fun lab_incident_draft(tree : list<state_entry>, incident_id : int) : <div> string
  read_component_named_state(tree, "incidents", incident_component_key(incident_id), "draft", text_state_codec, "")

pub fun finalize_incident_reply_tree(tree : list<state_entry>, incident_id : int) : <div> list<state_entry>
  clear_component_named_state_in_tree(
    assoc_component_named_state(tree, "incidents", incident_component_key(incident_id), "expanded", flag_state_codec, True),
    "incidents",
    incident_component_key(incident_id),
    "draft")

pub fun commit_lab_tree(owner : model, action : () -> <lab_local_effect,use_named_state,use_named_effect,current_hook_scope_name,push_hook_scope,pop_hook_scope|e> model) : <div|e> model
  val (next_model, next_tree, _pending_effect) = run_local_state(owner.app_local_tree, action)
  next_model(app_local_tree = next_tree)

pub fun set_local_lab_draft(owner : model, incident_id : int, draft : string) : <lab_local_effect> model
  if draft == "" then
    clear_component_named_state("incidents", incident_component_key(incident_id), "draft")
  else
    set_component_named_state("incidents", incident_component_key(incident_id), "draft", text_state_codec, draft)
  owner

pub fun toggle_local_lab_expanded(owner : model, incident_id : int) : <lab_local_effect> model
  set_component_named_state("incidents", incident_component_key(incident_id), "expanded", flag_state_codec, not(lab_incident_expanded(owner.app_local_tree, incident_id)))
  owner