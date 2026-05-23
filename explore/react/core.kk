module explore/react/core

pub type dom_event_kind
  Click_event
  Input_event
  Enter_event

pub struct attr(name : string, value : string)
pub struct listener(kind : dom_event_kind, payload : string)
pub struct vnode(tag : string, key : string, attrs : list<attr>, listeners : list<listener>, text : string, children : list<vnode>)
pub struct patch(path : string, kind : string, name : string, value : string, html : string)

pub fun dom_event_kind_name(kind : dom_event_kind) : string
  match kind
    Click_event -> "click"
    Input_event -> "input"
    Enter_event -> "enter"

fun auto_key() : string
  ""

// Construct a keyed VDOM node that can later be diffed and patched.
// Keep `key` stable among siblings; feature code should usually build nodes through `el(...)` and higher-level state/event helpers.
pub fun el(tag : string, key : string, attrs : list<attr>, listeners : list<listener>, text : string, children : list<vnode>) : vnode
  Vnode(tag, key, attrs, listeners, text, children)

// React-like tag helpers default to an automatic empty key; keep explicit keyed variants for lists and targeted tests.
pub fun div(attrs : list<attr>, children : list<vnode>) : vnode
  el("div", auto_key(), attrs, Nil, "", children)

pub fun div_key(key : string, attrs : list<attr>, children : list<vnode>) : vnode
  el("div", key, attrs, Nil, "", children)

pub fun section(attrs : list<attr>, children : list<vnode>) : vnode
  el("section", auto_key(), attrs, Nil, "", children)

pub fun section_key(key : string, attrs : list<attr>, children : list<vnode>) : vnode
  el("section", key, attrs, Nil, "", children)

pub fun article(attrs : list<attr>, children : list<vnode>) : vnode
  el("article", auto_key(), attrs, Nil, "", children)

pub fun article_key(key : string, attrs : list<attr>, children : list<vnode>) : vnode
  el("article", key, attrs, Nil, "", children)

pub fun aside(attrs : list<attr>, children : list<vnode>) : vnode
  el("aside", auto_key(), attrs, Nil, "", children)

pub fun header(attrs : list<attr>, children : list<vnode>) : vnode
  el("header", auto_key(), attrs, Nil, "", children)

pub fun nav(attrs : list<attr>, children : list<vnode>) : vnode
  el("nav", auto_key(), attrs, Nil, "", children)

pub fun nav_key(key : string, attrs : list<attr>, children : list<vnode>) : vnode
  el("nav", key, attrs, Nil, "", children)

pub fun ul(attrs : list<attr>, children : list<vnode>) : vnode
  el("ul", auto_key(), attrs, Nil, "", children)

pub fun ul_key(key : string, attrs : list<attr>, children : list<vnode>) : vnode
  el("ul", key, attrs, Nil, "", children)

pub fun li(attrs : list<attr>, children : list<vnode>) : vnode
  el("li", auto_key(), attrs, Nil, "", children)

pub fun li_key(key : string, attrs : list<attr>, children : list<vnode>) : vnode
  el("li", key, attrs, Nil, "", children)

pub fun li_text(attrs : list<attr>, text : string) : vnode
  el("li", auto_key(), attrs, Nil, text, Nil)

pub fun li_text_key(key : string, attrs : list<attr>, text : string) : vnode
  el("li", key, attrs, Nil, text, Nil)

pub fun span(attrs : list<attr>, text : string) : vnode
  el("span", auto_key(), attrs, Nil, text, Nil)

pub fun span_key(key : string, attrs : list<attr>, text : string) : vnode
  el("span", key, attrs, Nil, text, Nil)

pub fun strong(attrs : list<attr>, text : string) : vnode
  el("strong", auto_key(), attrs, Nil, text, Nil)

pub fun strong_key(key : string, attrs : list<attr>, text : string) : vnode
  el("strong", key, attrs, Nil, text, Nil)

pub fun p(attrs : list<attr>, text : string) : vnode
  el("p", auto_key(), attrs, Nil, text, Nil)

pub fun p_key(key : string, attrs : list<attr>, text : string) : vnode
  el("p", key, attrs, Nil, text, Nil)

pub fun h1(attrs : list<attr>, text : string) : vnode
  el("h1", auto_key(), attrs, Nil, text, Nil)

pub fun h2(attrs : list<attr>, text : string) : vnode
  el("h2", auto_key(), attrs, Nil, text, Nil)

pub fun h3(attrs : list<attr>, text : string) : vnode
  el("h3", auto_key(), attrs, Nil, text, Nil)

pub fun button(attrs : list<attr>, listeners : list<listener>, label : string) : vnode
  el("button", auto_key(), attrs, listeners, label, Nil)

pub fun button_key(key : string, attrs : list<attr>, listeners : list<listener>, label : string) : vnode
  el("button", key, attrs, listeners, label, Nil)

pub fun input(attrs : list<attr>, listeners : list<listener>) : vnode
  el("input", auto_key(), attrs, listeners, "", Nil)

pub fun input_key(key : string, attrs : list<attr>, listeners : list<listener>) : vnode
  el("input", key, attrs, listeners, "", Nil)

fun append_attrs(left : list<attr>, right : list<attr>) : <div> list<attr>
  match left
    Nil -> right
    Cons(head, rest) -> Cons(head, append_attrs(rest, right))

pub fun input_text(attrs : list<attr>, listeners : list<listener>, value : string, placeholder : string) : <div> vnode
  input(append_attrs([
    text_attr("type", "text"),
    text_attr("value", value),
    text_attr("placeholder", placeholder),
  ], attrs), listeners)

pub fun input_text_key(key : string, attrs : list<attr>, listeners : list<listener>, value : string, placeholder : string) : <div> vnode
  input_key(key, append_attrs([
    text_attr("type", "text"),
    text_attr("value", value),
    text_attr("placeholder", placeholder),
  ], attrs), listeners)

// Use this for CSS classes; prefer small helpers like this over spelling raw `Attr("class", ...)` at call-sites.
pub fun class_attr(value : string) : attr
  Attr("class", value)

// Generic attribute constructor for DOM-facing text attributes like `type`, `value`, or `placeholder`.
pub fun text_attr(name : string, value : string) : attr
  Attr(name, value)

// Low-level click listener constructor.
// In feature code, prefer `on_click(...)` from `explore/react/state` so handlers stay typed and can participate in the registry.
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

pub fun vnode_find_attr_value(node : vnode, name : string, value : string) : <div> maybe<vnode>
  if vnode_get_attr(node, name) == value then Just(node)
  else vnode_find_attr_value_in_children(vnode/children(node), name, value)

fun vnode_find_attr_value_in_children(children : list<vnode>, name : string, value : string) : <div> maybe<vnode>
  match children
    Nil -> Nothing
    Cons(child, rest) ->
      match vnode_find_attr_value(child, name, value)
        Just(found) -> Just(found)
        Nothing -> vnode_find_attr_value_in_children(rest, name, value)

pub fun vnode_find_text(node : vnode, target_text : string) : <div> maybe<vnode>
  if vnode/text(node) == target_text then Just(node)
  else vnode_find_text_in_children(vnode/children(node), target_text)

fun vnode_find_text_in_children(children : list<vnode>, target_text : string) : <div> maybe<vnode>
  match children
    Nil -> Nothing
    Cons(child, rest) ->
      match vnode_find_text(child, target_text)
        Just(found) -> Just(found)
        Nothing -> vnode_find_text_in_children(rest, target_text)

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
