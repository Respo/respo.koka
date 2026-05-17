module respo/core

pub struct attr(name : string, value : string)
pub struct listener(kind : string, payload : string)
pub struct vnode(tag : string, key : string, attrs : list<attr>, listeners : list<listener>, text : string, children : list<vnode>)
pub struct patch(path : string, kind : string, name : string, value : string, html : string)

pub fun attr_name(item : attr) : string
  match item
    Attr(name, _) -> name

pub fun attr_value(item : attr) : string
  match item
    Attr(_, value) -> value

pub fun listener_kind(item : listener) : string
  match item
    Listener(kind, _) -> kind

pub fun listener_payload(item : listener) : string
  match item
    Listener(_, payload) -> payload

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

// Construct a keyed VDOM node that can later be diffed and patched.
// Keep `key` stable among siblings; feature code should usually build nodes through `el(...)` and higher-level state/event helpers.
pub fun el(tag : string, key : string, attrs : list<attr>, listeners : list<listener>, text : string, children : list<vnode>) : vnode
  Vnode(tag, key, attrs, listeners, text, children)

// Use this for CSS classes; prefer small helpers like this over spelling raw `Attr("class", ...)` at call-sites.
pub fun class_attr(value : string) : attr
  Attr("class", value)

// Generic attribute constructor for DOM-facing text attributes like `type`, `value`, or `placeholder`.
pub fun text_attr(name : string, value : string) : attr
  Attr(name, value)

// Low-level string listener constructor.
// In feature code, prefer `on_click(...)` from `respo/state` so handlers stay typed and can participate in the registry.
pub fun click_listener(payload : string) : listener
  Listener("click", payload)

// Low-level input listener constructor.
// Prefer `on_input(...)` in app code unless you intentionally want raw string routing.
pub fun input_listener(payload : string) : listener
  Listener("input", payload)

// Low-level enter-key listener constructor.
// Prefer `on_enter(...)` in app code unless you intentionally want raw string routing.
pub fun enter_listener(payload : string) : listener
  Listener("enter", payload)
