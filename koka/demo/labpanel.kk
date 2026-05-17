module demo/labpanel

import demo/model
import demo/lab/events
import demo/lab/view
import respo/core

pub fun lab_panel(item : model) : <div> vnode
  render_lab_panel(item)

pub fun handle_lab_click(payload : string, owner : model) : <audit,current_operator,wait_ms,fetch_lab_snapshot,post_lab_reply,now_label,div> maybe<(model, maybe<string>)>
  route_lab_click(payload, owner)

pub fun handle_lab_input(channel : string, value : string, owner : model) : <div> maybe<model>
  route_lab_input(channel, value, owner)
