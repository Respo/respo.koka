module boilerplate/browserapp

import std/core/unsafe
import runtime/dom
import explore/react/core
import explore/react/renderer
import demo/model
import demo/seed
import demo/controller
import demo/view
import demo/tests
import library/bridge
import library/route
import explore/react/state

noinline val root_id_ref : ref<global,string> = unsafe-total { ref("app") }
noinline val model_ref : ref<global,model> = unsafe-total { ref(initial_model()) }
noinline val tree_ref : ref<global,vnode> = unsafe-total { ref(el("div", "root", Nil, Nil, "", Nil)) }
noinline val handlers_ref : ref<global,event_registry<model,browser_event_effect>> = unsafe-total { ref(empty_event_registry()) }

fun with_browser_host(action : () -> <browser_host,div|e> a) : <div|e> a
  with handler
    fun audit(message) browser_log(message)
    fun confirm_action(message) browser_confirm(message)
    val current_operator = "browser-operator"
    fun fetch_lab_snapshot() mock_lab_snapshot()
    fun now_label() browser_now_label()
    fun post_lab_reply(incident_id, message) mock_lab_reply(incident_id, message)
    fun wait_ms(delay) browser_log("Simulated wait " ++ delay.show ++ "ms")
  action()

fun with_browser(action : () -> <browser_host,request_bridge_resource,div|e> a) : <div|e> a
  with fun request_bridge_resource(payload, delay) browser_schedule_click(payload, delay)
  with_browser_host(action)

fun run_pending_effects(items : list<scheduled_effect>) : _e ()
  match items
    Nil -> ()
    Cons(item, rest) -> {
      run_scheduled_effect(item)
      run_pending_effects(rest)
    }

fun log_registry_warnings(messages : list<string>) : _e ()
  match messages
    Nil -> ()
    Cons(message, rest) -> {
      browser_log("[explore-react listener] " ++ message)
      log_registry_warnings(rest)
    }

fun commit(item : model) : _e ()
  val previous_handlers = !handlers_ref
  val (next_model, next_tree, pending_effects, next_handlers) = render_app(item, demo_test_results())
  val patches = diff_node("0", !tree_ref, next_tree)
  apply_patches(!root_id_ref, patches)
  browser_set_hash(next_model.route_name)
  model_ref := next_model
  tree_ref := next_tree
  handlers_ref := next_handlers
  log_registry_warnings(event_registry/warnings(next_handlers))
  log_registry_warnings(event_registry_semantic_warnings(previous_handlers, next_handlers))
  run_pending_effects(pending_effects)

fun next_click_model(payload : string, owner : model, handlers : event_registry<model,browser_event_effect>) : <div> model
  match find_registered_click(handlers, payload)
    Just(found_click) -> with_browser(fn() run_registered_click(found_click, owner))
    Nothing -> with_browser(fn() controller/dispatch_click(payload, owner))

fun next_input_model(channel : string, value : string, owner : model, handlers : event_registry<model,browser_event_effect>) : <div> model
  match find_registered_input(handlers, channel)
    Just(found_input) -> run_registered_input(found_input, value, owner)
    Nothing -> with_browser(fn() controller/dispatch_input(channel, value, owner))

fun dispatch_click(payload : string) : _e ()
  val owner = !model_ref
  val handlers = !handlers_ref
  val next_model = next_click_model(payload, owner, handlers)
  commit(next_model)

fun dispatch_input(channel : string, value : string) : _e ()
  val owner = !model_ref
  val handlers = !handlers_ref
  val next_model = next_input_model(channel, value, owner, handlers)
  commit(next_model)

pub fun dispatch_click_bridge(payload : string) : _e ()
  dispatch_click(payload)

pub fun dispatch_input_bridge(channel : string, value : string) : _e ()
  dispatch_input(channel, value)

pub fun dispatch_route_bridge(route_name : string) : _e ()
  commit((!model_ref)(route_name = normalize_route(route_name)))

pub fun boot(root_id : string) : _e ()
  root_id_ref := root_id
  set_root_id(root_id)
  attach_events(root_id)
  val start_model = initial_model()(route_name = normalize_route(browser_hash()))
  val (next_model, tree, pending_effects, handlers) = render_app(start_model, demo_test_results())
  model_ref := next_model
  tree_ref := tree
  handlers_ref := handlers
  mount_html(root_id, render_node("0", tree))
  browser_set_hash(next_model.route_name)
  log_registry_warnings(event_registry/warnings(handlers))
  run_pending_effects(pending_effects)