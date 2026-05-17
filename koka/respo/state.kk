module respo/state

pub effect fun use_state<a>(entry_slot : state_slot, codec : state_codec<a>, fallback : a) : a
pub effect fun set_state<a>(entry_slot : state_slot, codec : state_codec<a>, value : a) : ()
pub effect fun clear_local_state(path : string) : ()
pub effect fun use_effect(field_name : string) : ()

pub struct state_slot(path : string)

pub struct state_codec<a>(kind : string, read : (state_entry) -> a, write : (string, a) -> state_entry)

pub struct state_entry(path : string, kind : string, text_value : string, flag_value : bool)

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

pub fun count_entries(tree : list<state_entry>) : <div> int
  match tree
    Nil -> 0
    Cons(_, rest) -> 1 + count_entries(rest)

pub fun run_local_state(tree : list<state_entry>, action : () -> <use_state,set_state,clear_local_state,use_effect,div|e> a) : <div|e> (a, list<state_entry>, maybe<string>)
  var next_tree := tree
  var pending_effect := Nothing
  with return(result) (result, next_tree, pending_effect)
  with fun use_state(entry_slot, codec, fallback) state_value(next_tree, entry_slot, codec, fallback)
  with fun set_state(entry_slot, codec, value) next_tree := assoc_slot_value(next_tree, entry_slot, codec, value)
  with fun clear_local_state(path) next_tree := clear_state(next_tree, path)
  with fun use_effect(field_name) pending_effect := Just(field_name)
  action()
