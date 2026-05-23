module demo/tests/appharness

import demo/controller
import demo/model
import demo/view
import demo/tests/support
import library/bridge
import explore/react/core
import explore/react/state

pub fun app_harness(owner : model) : <div> component_harness
  val (next_model, tree, effects, registry) = render_app(owner, Nil)
  Component_harness(next_model, tree, effects, registry)

pub fun app_harness_click_payload(
  h : component_harness,
  payload : string
) : <audit,confirm_action,current_operator,fetch_lab_snapshot,now_label,post_lab_reply,request_bridge_resource,wait_ms,div> component_harness
  match find_registered_click(h.registry, payload)
    Just(found) -> app_harness(run_registered_click(found, h.owner))
    Nothing -> app_harness(controller/dispatch_click(payload, h.owner))

pub fun button_payload_by_text(tree : vnode, label : string) : <div> string
  match vnode_find_text(tree, label)
    Just(node) -> vnode_click_payload(node)
    Nothing -> ""

pub fun input_channel_by_effect_marker(tree : vnode, effect_marker : string) : <div> string
  match vnode_find_attr_value(tree, "data-k-effect", effect_marker)
    Just(node) -> vnode_input_channel(node)
    Nothing -> ""