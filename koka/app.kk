module app

import std/core/unsafe
import runtime/dom
import respo/core
import respo/renderer
import demo/model
import demo/seed
import demo/controller
import demo/view
import demo/tests

noinline val root_id_ref : ref<global,string> = unsafe-total { ref("app") }
noinline val model_ref : ref<global,model> = unsafe-total { ref(initial_model()) }
noinline val tree_ref : ref<global,vnode> = unsafe-total { ref(el("div", "root", Nil, Nil, "", Nil)) }

fun with_browser(action : () -> <audit,confirm_action,current_operator,fetch_lab_snapshot,now_label,post_lab_reply,wait_ms,io|e> a) : <io|e> a
  with fun audit(message) browser_log(message)
  with fun confirm_action(message) browser_confirm(message)
  with val current_operator = "browser-operator"
  with fun fetch_lab_snapshot() mock_lab_snapshot()
  with fun now_label() browser_now_label()
  with fun post_lab_reply(incident_id, message) mock_lab_reply(incident_id, message)
  with fun wait_ms(delay) browser_log("Simulated wait " ++ delay.show ++ "ms")
  action()

fun current_tree(item : model) : <div> vnode
  render_app(item, demo_test_results())

// Re-render through the respo core, diff against the previous VDOM tree, then patch the browser DOM.
fun commit(item : model, pending_focus : maybe<string>) : <io,div> ()
  val next_tree = current_tree(item)
  val patches = diff_node("0", !tree_ref, next_tree)
  apply_patches(!root_id_ref, patches)
  browser_set_hash(model_route_name(item))
  model_ref := item
  tree_ref := next_tree
  match pending_focus
    Just(field_name) -> browser_focus(!root_id_ref, field_name)
    Nothing -> ()

fun dispatch_click(payload : string) : <io,div> ()
  val (next_model, pending_focus) = with_browser(fn() controller/dispatch_click(payload, !model_ref))
  commit(next_model, pending_focus)

fun dispatch_input(channel : string, value : string) : <io,div> ()
  commit(controller/dispatch_input(channel, value, !model_ref), Nothing)

pub fun dispatch_click_bridge(payload : string) : <io,div> ()
  dispatch_click(payload)

pub fun dispatch_input_bridge(channel : string, value : string) : <io,div> ()
  dispatch_input(channel, value)

pub fun dispatch_route_bridge(route_name : string) : <io,div> ()
  commit(set_route(!model_ref, route_name), Nothing)

// The browser bridge stays intentionally thin: attach DOM listeners, render once, and keep all state transitions in Koka.
pub fun boot(root_id : string) : <io,div> ()
  root_id_ref := root_id
  attach_events(root_id)
  model_ref := set_route(initial_model(), browser_hash())
  val tree = current_tree(!model_ref)
  tree_ref := tree
  mount_html(root_id, render_node("0", tree))
  browser_set_hash(model_route_name(!model_ref))