module demo/lab/events

import demo/bridge
import demo/lab/search
import demo/model
import demo/lab/state
import demo/lab/workflow
import library/search
import respo/core

pub type lab_action
  Load_board
  Run_sync
  Load_bridge_case(case_name : string)
  Submit_search
  Search_for(query : string)
  Send_reply(incident_id : int)

pub fun lab_action_payload(action : lab_action) : string
  match action
    Load_board -> "lab-load"
    Run_sync -> "lab-sync"
    Load_bridge_case(case_name) -> bridge_load_payload(case_name)
    Submit_search -> search_submit_payload()
    Search_for(query) -> search_pick_payload(query)
    Send_reply(incident_id) -> "lab-send-" ++ incident_id.show

pub fun dispatch_lab_click(action : lab_action) : listener
  click_listener(lab_action_payload(action))

pub fun dispatch_lab_enter(action : lab_action) : listener
  enter_listener(lab_action_payload(action))

fun find_lab_draft_channel(channel : string, items : list<incident>) : <div> maybe<int>
  match find(items, fn(item) channel == "lab-draft-" ++ incident/id(item).show)
    Just(item) -> Just(item.id)
    Nothing -> Nothing

fun incident_id_from_toggle(payload : string, items : list<incident>) : <div> maybe<int>
  match find(items, fn(item) payload == "lab-toggle-" ++ incident/id(item).show)
    Just(item) -> Just(item.id)
    Nothing -> Nothing

fun incident_id_from_send(payload : string, items : list<incident>) : <div> maybe<int>
  match find(items, fn(item) payload == "lab-send-" ++ incident/id(item).show)
    Just(item) -> Just(item.id)
    Nothing -> Nothing

pub fun dispatch_lab_action(action : lab_action, owner : model) : <audit,current_operator,wait_ms,fetch_lab_snapshot,post_lab_reply,now_label,request_bridge_resource,div> model
  match action
    Load_board -> load_snapshot(owner)
    Run_sync -> perform_sync(owner)
    Load_bridge_case(case_name) -> start_bridge_case(owner, case_name)
    Submit_search -> start_search(owner)
    Search_for(query) -> pick_search_case(owner, query)
    Send_reply(incident_id) -> send_reply(owner, incident_id)

fun decode_lab_action(payload : string, owner : model) : <div> maybe<lab_action>
  if payload == "lab-load" then
    Just(Load_board)
  else if payload == "lab-sync" then
    Just(Run_sync)
  else if payload == search_submit_payload() then
    Just(Submit_search)
  else match decode_bridge_load_payload(payload)
    Just(case_name) -> Just(Load_bridge_case(case_name))
    Nothing -> match decode_search_pick_payload(payload)
      Just(query) -> Just(Search_for(query))
      Nothing -> match incident_id_from_send(payload, owner.lab.incidents)
        Just(incident_id) -> Just(Send_reply(incident_id))
        Nothing -> Nothing

pub fun route_lab_click(payload : string, owner : model) : <audit,current_operator,wait_ms,fetch_lab_snapshot,post_lab_reply,now_label,request_bridge_resource,div> maybe<model>
  match decode_lab_action(payload, owner)
    Just(action) -> Just(dispatch_lab_action(action, owner))
    Nothing -> match resolve_search_result(owner, payload)
      Just(result) -> Just(result)
      Nothing -> match resolve_bridge_result(owner, payload)
        Just(result) -> Just(result)
        Nothing -> match incident_id_from_toggle(payload, owner.lab.incidents)
          Just(target_id) -> Just(commit_lab_tree(owner, fn() toggle_local_lab_expanded(owner, target_id)))
          Nothing -> Nothing

pub fun route_lab_input(channel : string, value : string, owner : model) : <request_bridge_resource,div> maybe<model>
  if channel == search_query_channel() then
    Just(set_search_query(owner, value))
  else
    match find_lab_draft_channel(channel, owner.lab.incidents)
      Just(target_id) -> Just(commit_lab_tree(owner, fn() set_local_lab_draft(owner, target_id, value)))
      Nothing -> Nothing