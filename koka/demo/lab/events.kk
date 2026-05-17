module demo/lab/events

import demo/model
import demo/lab/state
import demo/lab/workflow
import respo/core

pub type lab_action
  Load_board
  Run_sync
  Send_reply(incident_id : int)

pub fun lab_action_payload(action : lab_action) : string
  match action
    Load_board -> "lab-load"
    Run_sync -> "lab-sync"
    Send_reply(incident_id) -> "lab-send-" ++ incident_id.show

pub fun dispatch_lab_click(action : lab_action) : listener
  click_listener(lab_action_payload(action))

pub fun dispatch_lab_enter(action : lab_action) : listener
  enter_listener(lab_action_payload(action))

fun find_lab_draft_channel(channel : string, items : list<incident>) : <div> maybe<int>
  match items
    Nil -> Nothing
    Cons(item, rest) -> if channel == incident_draft_channel(item) then Just(incident_id(item)) else find_lab_draft_channel(channel, rest)

fun has_lab_toggle(payload : string, items : list<incident>) : <div> bool
  match items
    Nil -> False
    Cons(item, rest) -> if payload == incident_toggle_payload(item) then True else has_lab_toggle(payload, rest)

fun has_lab_send(payload : string, items : list<incident>) : <div> bool
  match items
    Nil -> False
    Cons(item, rest) -> if payload == incident_send_payload(item) then True else has_lab_send(payload, rest)

fun incident_id_from_toggle(payload : string, items : list<incident>) : <div> maybe<int>
  match items
    Nil -> Nothing
    Cons(item, rest) -> if payload == incident_toggle_payload(item) then Just(incident_id(item)) else incident_id_from_toggle(payload, rest)

fun incident_id_from_send(payload : string, items : list<incident>) : <div> maybe<int>
  match items
    Nil -> Nothing
    Cons(item, rest) -> if payload == incident_send_payload(item) then Just(incident_id(item)) else incident_id_from_send(payload, rest)

pub fun dispatch_lab_action(action : lab_action, owner : model) : <audit,current_operator,wait_ms,fetch_lab_snapshot,post_lab_reply,now_label,div> model
  match action
    Load_board -> load_snapshot(owner)
    Run_sync -> perform_sync(owner)
    Send_reply(incident_id) -> send_reply(owner, incident_id)

fun decode_lab_action(payload : string, owner : model) : <div> maybe<lab_action>
  if payload == "lab-load" then
    Just(Load_board)
  else if payload == "lab-sync" then
    Just(Run_sync)
  else if has_lab_send(payload, lab_incidents(model_lab(owner))) then
    match incident_id_from_send(payload, lab_incidents(model_lab(owner)))
      Just(incident_id) -> Just(Send_reply(incident_id))
      Nothing -> Nothing
  else
    Nothing

pub fun route_lab_click(payload : string, owner : model) : <audit,current_operator,wait_ms,fetch_lab_snapshot,post_lab_reply,now_label,div> maybe<model>
  match decode_lab_action(payload, owner)
    Just(action) -> Just(dispatch_lab_action(action, owner))
    Nothing -> {
      if has_lab_toggle(payload, lab_incidents(model_lab(owner))) then
        match incident_id_from_toggle(payload, lab_incidents(model_lab(owner)))
          Just(target_id) -> Just(commit_lab_tree(owner, fn() toggle_local_lab_expanded(owner, target_id)))
          Nothing -> Just(set_notice(owner, "Workflow lab toggle target was missing."))
      else
        Nothing
    }

pub fun route_lab_input(channel : string, value : string, owner : model) : <div> maybe<model>
  match find_lab_draft_channel(channel, lab_incidents(model_lab(owner)))
    Just(target_id) -> Just(commit_lab_tree(owner, fn() set_local_lab_draft(owner, target_id, value)))
    Nothing -> Nothing