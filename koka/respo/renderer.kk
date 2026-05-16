module respo/renderer

import runtime/dom
import respo/core

fun attr_eq(left : attr, right : attr) : bool
  attr_name(left) == attr_name(right) && attr_value(left) == attr_value(right)

fun listener_eq(left : listener, right : listener) : bool
  listener_kind(left) == listener_kind(right) && listener_payload(left) == listener_payload(right)

fun find_attr(attrs : list<attr>, target_name : string) : <div> maybe<attr>
  match attrs
    Nil -> Nothing
    Cons(item, rest) -> if attr_name(item) == target_name then Just(item) else find_attr(rest, target_name)

fun attrs_eq(left : list<attr>, right : list<attr>) : <div> bool
  match left
    Nil ->
      match right
        Nil -> True
        _ -> False
    Cons(lx, lxs) ->
      match right
        Cons(rx, rxs) -> attr_eq(lx, rx) && attrs_eq(lxs, rxs)
        _ -> False

fun listeners_eq(left : list<listener>, right : list<listener>) : <div> bool
  match left
    Nil ->
      match right
        Nil -> True
        _ -> False
    Cons(lx, lxs) ->
      match right
        Cons(rx, rxs) -> listener_eq(lx, rx) && listeners_eq(lxs, rxs)
        _ -> False

fun child_keys_eq(left : list<vnode>, right : list<vnode>) : <div> bool
  match left
    Nil ->
      match right
        Nil -> True
        _ -> False
    Cons(lx, lxs) ->
      match right
        Cons(rx, rxs) -> vnode_key(lx) == vnode_key(rx) && child_keys_eq(lxs, rxs)
        _ -> False

fun join_path(path : string, index : int) : string
  path ++ "." ++ index.show

fun render_attrs(attrs : list<attr>) : <div> string
  match attrs
    Nil -> ""
    Cons(item, rest) -> " " ++ attr_name(item) ++ "=\"" ++ html_escape(attr_value(item)) ++ "\"" ++ render_attrs(rest)

fun render_listeners(listeners : list<listener>) : <div> string
  match listeners
    Nil -> ""
    Cons(item, rest) ->
      match listener_kind(item)
        "click" -> " data-k-click=\"" ++ html_escape(listener_payload(item)) ++ "\"" ++ render_listeners(rest)
        "input" -> " data-k-input=\"" ++ html_escape(listener_payload(item)) ++ "\"" ++ render_listeners(rest)
        "enter" -> " data-k-enter=\"" ++ html_escape(listener_payload(item)) ++ "\"" ++ render_listeners(rest)
        _ -> render_listeners(rest)

fun render_children(path : string, index : int, children : list<vnode>) : <div> string
  match children
    Nil -> ""
    Cons(child, rest) -> render_node(join_path(path, index), child) ++ render_children(path, index + 1, rest)

// Render a VDOM subtree into deterministic HTML so that tests and patching stay stable.
pub fun render_node(path : string, node : vnode) : <div> string
  val path_attr = Attr("data-kpath", path)
  val open_tag = "<" ++ vnode_tag(node) ++ render_attrs(Cons(path_attr, vnode_attrs(node))) ++ render_listeners(vnode_listeners(node))
  if vnode_tag(node) == "input" then
    open_tag ++ " />"
  else
    open_tag ++ ">" ++ html_escape(vnode_text(node)) ++ render_children(path, 0, vnode_children(node)) ++ "</" ++ vnode_tag(node) ++ ">"

fun replace_patch(path : string, node : vnode) : <div> list<patch>
  [Patch(path, "replace", "", "", render_node(path, node))]

fun set_attr_patch(path : string, name : string, value : string) : list<patch>
  [Patch(path, "set-attr", name, value, "")]

fun clear_attr_patch(path : string, name : string) : list<patch>
  [Patch(path, "clear-attr", name, "", "")]

fun append_patches(left : list<patch>, right : list<patch>) : <div> list<patch>
  match left
    Nil -> right
    Cons(item, rest) -> Cons(item, append_patches(rest, right))

fun diff_set_attr_patches(path : string, previous : list<attr>, next : list<attr>) : <div> list<patch>
  match next
    Nil -> Nil
    Cons(item, rest) ->
      val tail = diff_set_attr_patches(path, previous, rest)
      match find_attr(previous, attr_name(item))
        Just(found) -> if attr_value(found) == attr_value(item) then tail else append_patches(set_attr_patch(path, attr_name(item), attr_value(item)), tail)
        Nothing -> append_patches(set_attr_patch(path, attr_name(item), attr_value(item)), tail)

fun diff_clear_attr_patches(path : string, previous : list<attr>, next : list<attr>) : <div> list<patch>
  match previous
    Nil -> Nil
    Cons(item, rest) ->
      val tail = diff_clear_attr_patches(path, rest, next)
      match find_attr(next, attr_name(item))
        Just(_) -> tail
        Nothing -> append_patches(clear_attr_patch(path, attr_name(item)), tail)

fun diff_attr_patches(path : string, previous : list<attr>, next : list<attr>) : <div> list<patch>
  append_patches(diff_set_attr_patches(path, previous, next), diff_clear_attr_patches(path, previous, next))

fun diff_children(path : string, index : int, left : list<vnode>, right : list<vnode>) : <div> list<patch>
  match left
    Nil -> Nil
    Cons(lx, lxs) ->
      match right
        Cons(rx, rxs) -> append_patches(diff_node(join_path(path, index), lx, rx), diff_children(path, index + 1, lxs, rxs))
        _ -> Nil

// The initial diff strategy is intentionally small: if tags/keys/attrs/listeners/text differ,
// replace that subtree. This keeps the core readable before pursuing finer-grained patches.
pub fun diff_node(path : string, previous : vnode, next : vnode) : <div> list<patch>
  if vnode_tag(previous) != vnode_tag(next) then replace_patch(path, next)
  else if vnode_key(previous) != vnode_key(next) then replace_patch(path, next)
  else if not(listeners_eq(vnode_listeners(previous), vnode_listeners(next))) then replace_patch(path, next)
  else if vnode_text(previous) != vnode_text(next) then replace_patch(path, next)
  else if not(child_keys_eq(vnode_children(previous), vnode_children(next))) then replace_patch(path, next)
  else append_patches(diff_attr_patches(path, vnode_attrs(previous), vnode_attrs(next)), diff_children(path, 0, vnode_children(previous), vnode_children(next)))

// Apply previously computed patches through the DOM bridge. The browser remains the only imperative surface.
pub fun apply_patches(root_id : string, patches : list<patch>) : <div,io> ()
  match patches
    Nil -> ()
    Cons(item, rest) ->
      if patch_kind(item) == "replace" then
        patch_html(root_id, patch_path(item), patch_html_value(item))
      else if patch_kind(item) == "set-attr" then
        patch_attr(root_id, patch_path(item), patch_name(item), patch_value(item))
      else if patch_kind(item) == "clear-attr" then
        clear_attr(root_id, patch_path(item), patch_name(item))
      else
        ()
      apply_patches(root_id, rest)
