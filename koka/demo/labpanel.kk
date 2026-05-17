module demo/labpanel

import demo/model
import demo/lab/events
import demo/lab/view
import respo/core
import respo/state
import demo/lab/state

pub fun lab_panel(item : model) : <div> vnode
  val (_next_item, panel_node, _pending_effects) = run_lab_panel(item)
  panel_node

pub fun run_lab_panel(item : model) : <div> (model, vnode, list<scheduled_effect>)
  val lab = model_lab(item)
  val (panel_node, next_tree, pending_effects) = run_local_state(lab_local_tree(lab), fn() render_lab_panel(item))
  (set_lab_local_tree(item, next_tree), panel_node, pending_effects)

pub fun handle_lab_click(payload : string, owner : model) : <audit,current_operator,wait_ms,fetch_lab_snapshot,post_lab_reply,now_label,div> maybe<model>
  route_lab_click(payload, owner)

pub fun handle_lab_input(channel : string, value : string, owner : model) : <div> maybe<model>
  route_lab_input(channel, value, owner)
