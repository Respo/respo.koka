module demo/tests/support

import demo/bridge
import demo/dialogs
import demo/labpanel
import demo/model
import demo/seed
import respo/core
import respo/state

pub struct test_result(name : string, detail : string, passed : bool)

pub struct bridge_expectation
  first_request : string
  request_count : int
  audit_count : int
  visible_case : string
  requested_case : string
  shell_status : string
  detail_status : string

pub fun maybe_text(target : maybe<string>) : string
  match target
    Just(name) -> name
    Nothing -> "<none>"

pub fun first_text(items : list<string>) : string
  match items
    Cons(first, _rest) -> first
    Nil -> "<none>"

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

pub fun capture_audits(action : () -> <audit|e> model) : e (model, list<string>)
  var audits := Nil
  with return(result) (result, audits)
  with fun audit(message) audits := Cons(message, audits)
  action()

pub fun capture_bridge(action : () -> <request_bridge_resource,wait_ms,fetch_lab_snapshot,post_lab_reply,now_label,audit,current_operator|e> model) : e (model, list<string>, list<string>)
  var requests := Nil
  var audits := Nil
  with return(result) (result, requests, audits)
  with val current_operator = "test-operator"
  with fun wait_ms(_delay) ()
  with fun fetch_lab_snapshot() mock_lab_snapshot()
  with fun post_lab_reply(incident_id, message) mock_lab_reply(incident_id, message)
  with fun now_label() "T+120"
  with fun audit(message) audits := Cons(message, audits)
  with fun request_bridge_resource(payload, delay) requests := Cons(payload ++ "@" ++ delay.show, requests)
  action()

pub fun bridge_base_model() : model
  set_route(initial_model(), "lab")

pub fun bridge_click(owner : model, payload : string) : <request_bridge_resource,wait_ms,fetch_lab_snapshot,post_lab_reply,now_label,audit,current_operator,div> model
  match handle_lab_click(payload, owner)
    Just(result) -> result
    Nothing -> owner

pub fun capture_bridge_click(owner : model, payload : string) : <div> (model, list<string>, list<string>)
  capture_bridge(fn() bridge_click(owner, payload))

pub fun capture_bridge_load(owner : model, case_name : string) : <div> (model, list<string>, list<string>)
  capture_bridge_click(owner, bridge_load_payload(case_name))

pub fun capture_bridge_shell(owner : model, case_name : string, request_id : int) : <div> (model, list<string>, list<string>)
  capture_bridge_click(owner, bridge_result_payload("shell", case_name, request_id))

pub fun capture_bridge_detail(owner : model, case_name : string, request_id : int) : <div> (model, list<string>, list<string>)
  capture_bridge_click(owner, bridge_result_payload("detail", case_name, request_id))

pub fun bridge_ready_model(case_name : string) : <div> model
  val (started, _start_requests, _start_audits) = capture_bridge_load(bridge_base_model(), case_name)
  val (shell_ready, _shell_requests, _shell_audits) = capture_bridge_shell(started, case_name, 1)
  val (detail_ready, _detail_requests, _detail_audits) = capture_bridge_detail(shell_ready, case_name, 1)
  detail_ready

pub fun dialog_base_model() : model
  set_route(initial_model(), "effects")

pub fun dialog_click(owner : model, payload : string) : <audit,div> model
  match handle_dialog_click(payload, owner)
    Just(result) -> result
    Nothing -> owner

pub fun capture_dialog_click(owner : model, payload : string) : <div> (model, list<string>)
  capture_audits(fn() dialog_click(owner, payload))

pub fun bridge_expect(
  first_request : string,
  request_count : int,
  audit_count : int,
  visible_case : string,
  requested_case : string,
  shell_status : string,
  detail_status : string
) : bridge_expectation
  Bridge_expectation(first_request, request_count, audit_count, visible_case, requested_case, shell_status, detail_status)

pub fun bridge_expectation_result(owner : model, requests : list<string>, audits : list<string>, expected : bridge_expectation) : <div> (string, bool)
  val demo = lab_bridge_demo(model_lab(owner))
  val request_label = first_text(requests)
  val request_count = length(requests)
  val audit_count = length(audits)
  val detail =
    "request=" ++ request_label ++
    ", requests=" ++ request_count.show ++
    ", audits=" ++ audit_count.show ++
    ", visible=" ++ bridge_visible_case(demo) ++
    ", requested=" ++ bridge_requested_case(demo) ++
    ", shell=" ++ bridge_shell_status(demo) ++
    ", detail=" ++ bridge_detail_status(demo)
  val passed =
    request_label == bridge_expectation/first_request(expected) &&
    request_count == bridge_expectation/request_count(expected) &&
    audit_count == bridge_expectation/audit_count(expected) &&
    bridge_visible_case(demo) == bridge_expectation/visible_case(expected) &&
    bridge_requested_case(demo) == bridge_expectation/requested_case(expected) &&
    bridge_shell_status(demo) == bridge_expectation/shell_status(expected) &&
    bridge_detail_status(demo) == bridge_expectation/detail_status(expected)
  (detail, passed)

fun attrs_have_value(attrs : list<attr>, target_name : string, target_value : string) : <div> bool
  any(attrs, fn(item) attr_name(item) == target_name && attr_value(item) == target_value)

fun children_have_attr_value(nodes : list<vnode>, target_name : string, target_value : string) : <div> bool
  any(nodes, fn(node) vnode_has_attr_value(node, target_name, target_value))

pub fun vnode_has_attr_value(node : vnode, target_name : string, target_value : string) : <div> bool
  attrs_have_value(vnode_attrs(node), target_name, target_value) || children_have_attr_value(vnode_children(node), target_name, target_value)