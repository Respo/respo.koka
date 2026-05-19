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

pub fun attr_name(item : attr) : string
  match item
    Attr(name, _) -> name

pub fun attr_value(item : attr) : string
  match item
    Attr(_, value) -> value

pub fun listener_kind(item : listener) : dom_event_kind
  match item
    Listener(kind, _) -> kind

pub fun dom_event_kind_name(kind : dom_event_kind) : string
  match kind
    Click_event -> "click"
    Input_event -> "input"
    Enter_event -> "enter"

pub fun listener_payload(item : listener) : string
  match item
    Listener(_, payload) -> payload

pub fun node_props_attrs(item : node_props) : list<attr>
  match item
    Node_props(attrs, _) -> attrs

pub fun node_props_listeners(item : node_props) : list<listener>
  match item
    Node_props(_, listeners) -> listeners

pub fun vnode_tag(item : vnode) : string
  match item
    Vnode(tag, _, _, _, _, _) -> tag

pub fun vnode_key(item : vnode) : string
  match item
    Vnode(_, key, _, _, _, _) -> key

pub fun vnode_attrs(item : vnode) : list<attr>
  match item
    Vnode(_, _, attrs, _, _, _) -> attrs

pub fun vnode_listeners(item : vnode) : list<listener>
  match item
    Vnode(_, _, _, listeners, _, _) -> listeners

pub fun vnode_text(item : vnode) : string
  match item
    Vnode(_, _, _, _, text, _) -> text

pub fun vnode_children(item : vnode) : list<vnode>
  match item
    Vnode(_, _, _, _, _, children) -> children

pub fun patch_path(item : patch) : string
  match item
    Patch(path, _, _, _, _) -> path

pub fun patch_kind(item : patch) : string
  match item
    Patch(_, kind, _, _, _) -> kind

pub fun patch_name(item : patch) : string
  match item
    Patch(_, _, name, _, _) -> name

pub fun patch_value(item : patch) : string
  match item
    Patch(_, _, _, value, _) -> value

pub fun patch_html_value(item : patch) : string
  match item
    Patch(_, _, _, _, html) -> html

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
  el(tag, key, node_props_attrs(options), node_props_listeners(options), "", children)

pub fun text_node(tag : string, key : string, options : node_props, text : string) : vnode
  el(tag, key, node_props_attrs(options), node_props_listeners(options), text, Nil)

pub fun leaf_node(tag : string, key : string, options : node_props) : vnode
  el(tag, key, node_props_attrs(options), node_props_listeners(options), "", Nil)

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
