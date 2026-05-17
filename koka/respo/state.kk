module respo/state

import respo/core

pub effect fun use_state<a>(entry_slot : state_slot, codec : state_codec<a>, fallback : a) : a
pub effect fun set_state<a>(entry_slot : state_slot, codec : state_codec<a>, value : a) : ()
pub effect fun clear_local_state(path : string) : ()
pub effect fun use_effect(effect_slot : state_slot, deps : list<string>, action : (string) -> io ()) : ()
pub effect<s,e::E> fun on_click(entry_slot : state_slot, action : (s) -> <div|e> s) : listener
pub effect<s> fun on_input(entry_slot : state_slot, action : (string, s) -> <div> s) : listener
pub effect<s,e::E> fun on_enter(entry_slot : state_slot, action : (s) -> <div|e> s) : listener

pub struct state_slot(path : string)

pub struct state_codec<a>(kind : string, read : (state_entry) -> a, write : (string, a) -> state_entry)

pub struct state_entry(path : string, kind : string, text_value : string, flag_value : bool)

pub struct scheduled_effect(path : string, run : (string) -> io ())
pub struct registered_click<s,e::E>(id : string, run : (s) -> <div|e> s)
pub struct registered_input<s>(id : string, run : (string, s) -> <div> s)
pub struct event_registry<s,e::E>(clicks : list<registered_click<s,e>>, inputs : list<registered_input<s>>)

pub fun state_slot_path(item : state_slot) : string
  match item
    State_slot(path) -> path

pub fun state_codec_kind(item : state_codec<a>) : string
  match item
    State_codec(kind, _, _) -> kind

fun state_codec_read(item : state_codec<a>, entry : state_entry) : a
  match item
    State_codec(_, read, _) -> read(entry)

fun state_codec_write(item : state_codec<a>, path : string, value : a) : state_entry
  match item
    State_codec(_, _, write) -> write(path, value)

fun join_slot_path(base : string, name : string) : string
  if base == "" then name else base ++ "/" ++ name

fun normalize_slot_name(name : string) : string
  match list(name)
    Nil -> "slot"
    Cons(head, _rest) -> if head >= '0' && head <= '9' then "_" ++ name else name

pub fun slot(base : string, index : int) : state_slot
  State_slot(join_slot_path(base, index.show))

pub fun named_slot(base : string, name : string) : state_slot
  State_slot(join_slot_path(base, normalize_slot_name(name)))

pub val text_state_codec : state_codec<string> = State_codec(
  "text",
  fn(entry) state_entry_text_value(entry),
  fn(path, value) State_entry(path, "text", value, False))

pub val flag_state_codec : state_codec<bool> = State_codec(
  "flag",
  fn(entry) state_entry_flag_value(entry),
  fn(path, value) State_entry(path, "flag", "", value))

pub fun state_entry_path(item : state_entry) : string
  match item
    State_entry(path, _, _, _) -> path

pub fun state_entry_kind(item : state_entry) : string
  match item
    State_entry(_, kind, _, _) -> kind

pub fun state_entry_text_value(item : state_entry) : string
  match item
    State_entry(_, _, text_value, _) -> text_value

pub fun state_entry_flag_value(item : state_entry) : bool
  match item
    State_entry(_, _, _, flag_value) -> flag_value

pub fun scheduled_effect_path(item : scheduled_effect) : string
  match item
    Scheduled_effect(path, _) -> path

pub fun registered_click_id<s,e::E>(item : registered_click<s,e>) : string
  match item
    Registered_click(id, _) -> id

pub fun registered_input_id<s>(item : registered_input<s>) : string
  match item
    Registered_input(id, _) -> id

pub fun run_registered_click<s,e::E>(item : registered_click<s,e>, owner : s) : <div|e> s
  match item
    Registered_click(_, run) -> run(owner)

pub fun run_registered_input<s>(item : registered_input<s>, value : string, owner : s) : <div> s
  match item
    Registered_input(_, run) -> run(value, owner)

pub fun event_registry_clicks<s,e::E>(item : event_registry<s,e>) : list<registered_click<s,e>>
  match item
    Event_registry(clicks, _) -> clicks

pub fun event_registry_inputs<s,e::E>(item : event_registry<s,e>) : list<registered_input<s>>
  match item
    Event_registry(_, inputs) -> inputs

pub fun empty_event_registry<s,e::E>() : event_registry<s,e>
  Event_registry(Nil, Nil)

pub fun run_scheduled_effect(item : scheduled_effect, root_id : string) : io ()
  match item
    Scheduled_effect(_, run) -> run(root_id)

fun append_registered_click<s,e::E>(items : list<registered_click<s,e>>, item : registered_click<s,e>) : <div> list<registered_click<s,e>>
  match items
    Nil -> [item]
    Cons(head, rest) -> Cons(head, append_registered_click(rest, item))

fun append_registered_input<s>(items : list<registered_input<s>>, item : registered_input<s>) : <div> list<registered_input<s>>
  match items
    Nil -> [item]
    Cons(head, rest) -> Cons(head, append_registered_input(rest, item))

pub fun append_event_registries<s,e::E>(left : event_registry<s,e>, right : event_registry<s,e>) : <div> event_registry<s,e>
  match left
    Event_registry(left_clicks, left_inputs) ->
      match right
        Event_registry(right_clicks, right_inputs) -> Event_registry(append_registered_clicks(left_clicks, right_clicks), append_registered_inputs(left_inputs, right_inputs))

fun append_registered_clicks<s,e::E>(left : list<registered_click<s,e>>, right : list<registered_click<s,e>>) : <div> list<registered_click<s,e>>
  match left
    Nil -> right
    Cons(head, rest) -> Cons(head, append_registered_clicks(rest, right))

fun append_registered_inputs<s>(left : list<registered_input<s>>, right : list<registered_input<s>>) : <div> list<registered_input<s>>
  match left
    Nil -> right
    Cons(head, rest) -> Cons(head, append_registered_inputs(rest, right))

pub fun find_registered_click<s,e::E>(registry : event_registry<s,e>, target_id : string) : <div> maybe<registered_click<s,e>>
  find_click_in_list(event_registry_clicks(registry), target_id)

fun find_click_in_list<s,e::E>(items : list<registered_click<s,e>>, target_id : string) : <div> maybe<registered_click<s,e>>
  match items
    Nil -> Nothing
    Cons(item, rest) -> if registered_click_id(item) == target_id then Just(item) else find_click_in_list(rest, target_id)

pub fun find_registered_input<s,e::E>(registry : event_registry<s,e>, target_id : string) : <div> maybe<registered_input<s>>
  find_input_in_list(event_registry_inputs(registry), target_id)

fun find_input_in_list<s>(items : list<registered_input<s>>, target_id : string) : <div> maybe<registered_input<s>>
  match items
    Nil -> Nothing
    Cons(item, rest) -> if registered_input_id(item) == target_id then Just(item) else find_input_in_list(rest, target_id)

pub fun count_registered_clicks<s,e::E>(registry : event_registry<s,e>) : <div> int
  count_click_items(event_registry_clicks(registry))

fun count_click_items<s,e::E>(items : list<registered_click<s,e>>) : <div> int
  match items
    Nil -> 0
    Cons(_, rest) -> 1 + count_click_items(rest)

pub fun count_registered_inputs<s,e::E>(registry : event_registry<s,e>) : <div> int
  count_input_items(event_registry_inputs(registry))

fun count_input_items<s>(items : list<registered_input<s>>) : <div> int
  match items
    Nil -> 0
    Cons(_, rest) -> 1 + count_input_items(rest)

pub fun slot_text(tree : list<state_entry>, entry_slot : state_slot, fallback : string) : <div> string
  state_value(tree, entry_slot, text_state_codec, fallback)

pub fun slot_flag(tree : list<state_entry>, entry_slot : state_slot, fallback : bool) : <div> bool
  state_value(tree, entry_slot, flag_state_codec, fallback)

pub fun state_value(tree : list<state_entry>, entry_slot : state_slot, codec : state_codec<a>, fallback : a) : <div> a
  match find_state(tree, state_slot_path(entry_slot))
    Just(item) -> if state_entry_kind(item) == state_codec_kind(codec) then state_codec_read(codec, item) else fallback
    _ -> fallback

pub fun assoc_slot_text(tree : list<state_entry>, entry_slot : state_slot, text : string) : <div> list<state_entry>
  assoc_slot_value(tree, entry_slot, text_state_codec, text)

pub fun assoc_slot_flag(tree : list<state_entry>, entry_slot : state_slot, flag : bool) : <div> list<state_entry>
  assoc_slot_value(tree, entry_slot, flag_state_codec, flag)

pub fun assoc_slot_value(tree : list<state_entry>, entry_slot : state_slot, codec : state_codec<a>, value : a) : <div> list<state_entry>
  assoc_entry(tree, state_codec_write(codec, state_slot_path(entry_slot), value))

pub fun clear_slot_state(tree : list<state_entry>, entry_slot : state_slot) : <div> list<state_entry>
  clear_state(tree, state_slot_path(entry_slot))

pub fun use_slot_state(entry_slot : state_slot, codec : state_codec<a>, fallback : a) : <use_state,div> a
  use_state(entry_slot, codec, fallback)

pub fun set_slot_state(entry_slot : state_slot, codec : state_codec<a>, value : a) : <set_state,div> ()
  set_state(entry_slot, codec, value)

pub fun use_state_pair(entry_slot : state_slot, codec : state_codec<a>, fallback : a) : <use_state,div> (a, (a) -> <set_state,div> ())
  (use_state(entry_slot, codec, fallback), fn(value) set_state(entry_slot, codec, value))

pub fun run_event_registry<s,e::E,a>(action : () -> <on_click<s,e>,on_input<s>,on_enter<s,e>,div> a) : <div> (a, event_registry<s,e>)
  var registered_clicks := Nil
  var registered_inputs := Nil
  with return(result) (result, Event_registry(registered_clicks, registered_inputs))
  with fun on_click(entry_slot, callback) {
    val handler_id = state_slot_path(entry_slot)
    registered_clicks := append_registered_click(registered_clicks, Registered_click(handler_id, callback))
    Listener("click", handler_id)
  }
  with fun on_input(entry_slot, callback) {
    val handler_id = state_slot_path(entry_slot)
    registered_inputs := append_registered_input(registered_inputs, Registered_input(handler_id, callback))
    Listener("input", handler_id)
  }
  with fun on_enter(entry_slot, callback) {
    val handler_id = state_slot_path(entry_slot)
    registered_clicks := append_registered_click(registered_clicks, Registered_click(handler_id, callback))
    Listener("enter", handler_id)
  }
  action()

pub fun read_local_state(tree : list<state_entry>, action : () -> <use_state,div|e> a) : <div|e> a
  with fun use_state(entry_slot, codec, fallback) state_value(tree, entry_slot, codec, fallback)
  action()

pub fun clear_slot(entry_slot : state_slot) : <clear_local_state,div> ()
  clear_local_state(state_slot_path(entry_slot))

fun find_state(tree : list<state_entry>, path : string) : <div> maybe<state_entry>
  match tree
    Nil -> Nothing
    Cons(item, rest) -> if state_entry_path(item) == path then Just(item) else find_state(rest, path)

fun assoc_entry(tree : list<state_entry>, next_entry : state_entry) : <div> list<state_entry>
  match tree
    Nil -> [next_entry]
    Cons(item, rest) ->
      if state_entry_path(item) == state_entry_path(next_entry) then
        Cons(next_entry, rest)
      else
        Cons(item, assoc_entry(rest, next_entry))

// State is keyed by stable component paths so more local UI state can move out of the main domain model later.
pub fun state_text(tree : list<state_entry>, path : string, fallback : string) : <div> string
  state_value(tree, State_slot(path), text_state_codec, fallback)

pub fun state_flag(tree : list<state_entry>, path : string, fallback : bool) : <div> bool
  state_value(tree, State_slot(path), flag_state_codec, fallback)

pub fun assoc_text(tree : list<state_entry>, path : string, text : string) : <div> list<state_entry>
  assoc_slot_value(tree, State_slot(path), text_state_codec, text)

pub fun assoc_flag(tree : list<state_entry>, path : string, flag : bool) : <div> list<state_entry>
  assoc_slot_value(tree, State_slot(path), flag_state_codec, flag)

pub fun clear_state(tree : list<state_entry>, path : string) : <div> list<state_entry>
  match tree
    Nil -> Nil
    Cons(item, rest) -> if state_entry_path(item) == path then rest else Cons(item, clear_state(rest, path))

fun append_scheduled_effect(items : list<scheduled_effect>, item : scheduled_effect) : <div> list<scheduled_effect>
  match items
    Nil -> [item]
    Cons(head, rest) -> Cons(head, append_scheduled_effect(rest, item))

pub fun append_scheduled_effects(left : list<scheduled_effect>, right : list<scheduled_effect>) : <div> list<scheduled_effect>
  match left
    Nil -> right
    Cons(head, rest) -> Cons(head, append_scheduled_effects(rest, right))

fun effect_signature(deps : list<string>) : <div> string
  match deps
    Nil -> ""
    Cons(head, rest) ->
      if rest == Nil then head else head ++ "\u001f" ++ effect_signature(rest)

fun effect_entry(slot_item : state_slot, deps : list<string>) : <div> state_entry
  State_entry(state_slot_path(slot_item), "effect", effect_signature(deps), False)

pub fun count_entries(tree : list<state_entry>) : <div> int
  match tree
    Nil -> 0
    Cons(_, rest) -> 1 + count_entries(rest)

pub fun run_local_state(tree : list<state_entry>, action : () -> <use_state,set_state,clear_local_state,use_effect,div|e> a) : <div|e> (a, list<state_entry>, list<scheduled_effect>)
  var next_tree := tree
  var pending_effects := Nil
  with return(result) (result, next_tree, pending_effects)
  with fun use_state(entry_slot, codec, fallback) state_value(next_tree, entry_slot, codec, fallback)
  with fun set_state(entry_slot, codec, value) next_tree := assoc_slot_value(next_tree, entry_slot, codec, value)
  with fun clear_local_state(path) next_tree := clear_state(next_tree, path)
  with fun use_effect(effect_slot, deps, callback) {
    val next_entry = effect_entry(effect_slot, deps)
    val changed = match find_state(next_tree, state_slot_path(effect_slot))
      Just(found) -> state_entry_kind(found) != "effect" || state_entry_text_value(found) != state_entry_text_value(next_entry)
      Nothing -> True
    next_tree := assoc_entry(next_tree, next_entry)
    if changed then pending_effects := append_scheduled_effect(pending_effects, Scheduled_effect(state_slot_path(effect_slot), callback)) else ()
  }
  action()
