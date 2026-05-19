module demo/tests/support

import demo/model
import demo/seed
import respo/core
import respo/state

pub struct test_result(name : string, detail : string, passed : bool)

pub fun maybe_text(target : maybe<string>) : string
  match target
    Just(name) -> name
    Nothing -> "<none>"

pub fun capture_waits(action : () -> <wait_ms|e> string) : e (string, list<int>)
  var waits := Nil
  with return(result) (result, waits)
  with fun wait_ms(delay) waits := Cons(delay, waits)
  action()

pub fun capture_workflow(action : () -> <wait_ms,fetch_lab_snapshot,post_lab_reply,now_label,audit,current_operator|e> model) : e (model, list<int>, list<string>)
  var waits := Nil
  var audits := Nil
  with return(result) (result, waits, audits)
  with val current_operator = "test-operator"
  with fun wait_ms(delay) waits := Cons(delay, waits)
  with fun fetch_lab_snapshot() mock_lab_snapshot()
  with fun post_lab_reply(incident_id, message) mock_lab_reply(incident_id, message)
  with fun now_label() "T+120"
  with fun audit(message) audits := Cons(message, audits)
  action()

fun attrs_have_value(attrs : list<attr>, target_name : string, target_value : string) : <div> bool
  any(attrs, fn(item) attr_name(item) == target_name && attr_value(item) == target_value)

fun children_have_attr_value(nodes : list<vnode>, target_name : string, target_value : string) : <div> bool
  any(nodes, fn(node) vnode_has_attr_value(node, target_name, target_value))

pub fun vnode_has_attr_value(node : vnode, target_name : string, target_value : string) : <div> bool
  attrs_have_value(vnode_attrs(node), target_name, target_value) || children_have_attr_value(vnode_children(node), target_name, target_value)