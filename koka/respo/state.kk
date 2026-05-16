module respo/state

pub struct state_entry(path : string, kind : string, text_value : string, flag_value : bool)

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

fun find_state(tree : list<state_entry>, path : string) : <div> maybe<state_entry>
  match tree
    Nil -> Nothing
    Cons(item, rest) -> if state_entry_path(item) == path then Just(item) else find_state(rest, path)

// State is keyed by stable component paths so more local UI state can move out of the main domain model later.
pub fun state_text(tree : list<state_entry>, path : string, fallback : string) : <div> string
  match find_state(tree, path)
    Just(item) -> if state_entry_kind(item) == "text" then state_entry_text_value(item) else fallback
    _ -> fallback

pub fun state_flag(tree : list<state_entry>, path : string, fallback : bool) : <div> bool
  match find_state(tree, path)
    Just(item) -> if state_entry_kind(item) == "flag" then state_entry_flag_value(item) else fallback
    _ -> fallback

fun assoc_value(tree : list<state_entry>, path : string, kind : string, text_value : string, flag_value : bool) : <div> list<state_entry>
  match tree
    Nil -> [State_entry(path, kind, text_value, flag_value)]
    Cons(item, rest) ->
      if state_entry_path(item) == path then
        Cons(State_entry(path, kind, text_value, flag_value), rest)
      else
        Cons(item, assoc_value(rest, path, kind, text_value, flag_value))

pub fun assoc_text(tree : list<state_entry>, path : string, text : string) : <div> list<state_entry>
  assoc_value(tree, path, "text", text, False)

pub fun assoc_flag(tree : list<state_entry>, path : string, flag : bool) : <div> list<state_entry>
  assoc_value(tree, path, "flag", "", flag)

pub fun clear_state(tree : list<state_entry>, path : string) : <div> list<state_entry>
  match tree
    Nil -> Nil
    Cons(item, rest) -> if state_entry_path(item) == path then rest else Cons(item, clear_state(rest, path))

pub fun count_entries(tree : list<state_entry>) : <div> int
  match tree
    Nil -> 0
    Cons(_, rest) -> 1 + count_entries(rest)
