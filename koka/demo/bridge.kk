module demo/bridge

import demo/model

pub struct bridge_signal
  resource_tag : string
  resource_key : string
  request_id : int

pub fun bridge_load_payload(resource_key : string) : string
  "bridge-load|" ++ resource_key

pub fun decode_bridge_load_payload(payload : string) : <div> maybe<string>
  match split(payload, "|")
    ["bridge-load", resource_key] -> Just(resource_key)
    _ -> Nothing

pub fun bridge_result_payload(resource_kind : string, resource_key : string, request_id : int) : string
  "bridge-" ++ resource_kind ++ "|" ++ resource_key ++ "|" ++ request_id.show

pub fun decode_bridge_result_payload(payload : string) : <div> maybe<bridge_signal>
  match split(payload, "|")
    [resource_tag, resource_key, request_id_text] -> match parse-int(request_id_text)
      Just(request_id) -> Just(Bridge_signal(resource_tag, resource_key, request_id))
      Nothing -> Nothing
    _ -> Nothing

pub fun request_bridge_result(resource_kind : string, resource_key : string, request_id : int, delay : int) : <request_bridge_resource,div> ()
  request_bridge_resource(bridge_result_payload(resource_kind, resource_key, request_id), delay)