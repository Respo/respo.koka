module respo/core

pub type dom_event_kind
  Click_event
  Input_event
  Enter_event

pub struct attr(name : string, value : string)
pub struct listener(kind : dom_event_kind, payload : string)
pub struct node_props(attrs : list<attr>, listeners : list<listener>)
pub struct vnode(tag : string, key : string, attrs : list<attr>, listeners : list<listener>, text : string, children : list<vnode>)
pub struct patch(path : string, kind : string, name : string, value : string, html : string)

pub fun dom_event_kind_name(kind : dom_event_kind) : string
  match kind
    Click_event -> "click"
    Input_event -> "input"
    Enter_event -> "enter"

pub fun props(attrs : list<attr>, listeners : list<listener>) : node_props
  Node_props(attrs, listeners)

pub fun class_props(class_name : string) : node_props
  props([class_attr(class_name)], Nil)

pub val empty_props : node_props = Node_props(Nil, Nil)

// Construct a keyed VDOM node that can later be diffed and patched.
// Keep `key` stable among siblings; feature code should usually build nodes through `el(...)` and higher-level state/event helpers.
pub fun el(tag : string, key : string, attrs : list<attr>, listeners : list<listener>, text : string, children : list<vnode>) : vnode
  Vnode(tag, key, attrs, listeners, text, children)

// React-like constructors that group attrs/listeners as props and separate text-vs-children rendering.
pub fun node(tag : string, key : string, options : node_props, children : list<vnode>) : vnode
  el(tag, key, node_props/attrs(options), node_props/listeners(options), "", children)

pub fun text_node(tag : string, key : string, options : node_props, text : string) : vnode
  el(tag, key, node_props/attrs(options), node_props/listeners(options), text, Nil)

pub fun leaf_node(tag : string, key : string, options : node_props) : vnode
  el(tag, key, node_props/attrs(options), node_props/listeners(options), "", Nil)

pub fun node_class(tag : string, key : string, class_name : string, children : list<vnode>) : vnode
  node(tag, key, class_props(class_name), children)

pub fun text_class(tag : string, key : string, class_name : string, text : string) : vnode
  text_node(tag, key, class_props(class_name), text)

pub fun button_class(key : string, class_name : string, listeners : list<listener>, label : string) : vnode
  text_node("button", key, props([class_attr(class_name)], listeners), label)

fun append_attrs(left : list<attr>, right : list<attr>) : <div> list<attr>
  match left
    Nil -> right
    Cons(head, rest) -> Cons(head, append_attrs(rest, right))

pub fun text_input(key : string, class_name : string, value : string, placeholder : string, extra_attrs : list<attr>, listeners : list<listener>) : <div> vnode
  leaf_node("input", key, props(append_attrs([
    class_attr(class_name),
    text_attr("type", "text"),
    text_attr("value", value),
    text_attr("placeholder", placeholder),
  ], extra_attrs), listeners))

// Use this for CSS classes; prefer small helpers like this over spelling raw `Attr("class", ...)` at call-sites.
pub fun class_attr(value : string) : attr
  Attr("class", value)

// Generic attribute constructor for DOM-facing text attributes like `type`, `value`, or `placeholder`.
pub fun text_attr(name : string, value : string) : attr
  Attr(name, value)

// Low-level click listener constructor.
// In feature code, prefer `on_click(...)` from `respo/state` so handlers stay typed and can participate in the registry.
pub fun click_listener(payload : string) : listener
  Listener(Click_event, payload)

// Low-level input listener constructor.
// Prefer `on_input(...)` in app code unless you intentionally want raw string routing.
pub fun input_listener(payload : string) : listener
  Listener(Input_event, payload)

// Low-level enter-key listener constructor.
// Prefer `on_enter(...)` in app code unless you intentionally want raw string routing.
pub fun enter_listener(payload : string) : listener
  Listener(Enter_event, payload)

// --- Vnode query helpers (useful in tests and inspectors) ---

// Recursively find the first vnode in the subtree whose key matches target_key.
pub fun vnode_find_key(node : vnode, target_key : string) : <div> maybe<vnode>
  if vnode/key(node) == target_key then Just(node)
  else vnode_find_key_in_children(vnode/children(node), target_key)

fun vnode_find_key_in_children(children : list<vnode>, target : string) : <div> maybe<vnode>
  match children
    Nil -> Nothing
    Cons(child, rest) ->
      match vnode_find_key(child, target)
        Just(found) -> Just(found)
        Nothing -> vnode_find_key_in_children(rest, target)

// Return the value of an attribute by name; "" if not present.
pub fun vnode_get_attr(node : vnode, name : string) : string
  find_vnode_attr(vnode/attrs(node), name)

fun find_vnode_attr(attrs : list<attr>, name : string) : string
  match attrs
    Nil -> ""
    Cons(item, rest) -> if attr/name(item) == name then attr/value(item) else find_vnode_attr(rest, name)

// Return the payload of the first click listener on a node; "" if absent.
pub fun vnode_click_payload(node : vnode) : string
  find_listener_payload_by_kind(vnode/listeners(node), Click_event)

// Return the channel of the first input listener on a node; "" if absent.
pub fun vnode_input_channel(node : vnode) : string
  find_listener_payload_by_kind(vnode/listeners(node), Input_event)

fun find_listener_payload_by_kind(listeners : list<listener>, target : dom_event_kind) : string
  match listeners
    Nil -> ""
    Cons(item, rest) ->
      match (listener/kind(item), target)
        (Click_event, Click_event) -> listener/payload(item)
        (Input_event, Input_event) -> listener/payload(item)
        (Enter_event, Enter_event) -> listener/payload(item)
        _ -> find_listener_payload_by_kind(rest, target)
