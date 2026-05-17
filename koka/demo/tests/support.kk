module demo/tests/support

import demo/model
import demo/seed
import respo/core
import respo/state

pub struct test_result(name : string, detail : string, passed : bool)

pub fun test_name(item : test_result) : string
  match item
    Test_result(name, _, _) -> name

pub fun test_detail(item : test_result) : string
  match item
    Test_result(_, detail, _) -> detail

pub fun test_passed(item : test_result) : bool
  match item
    Test_result(_, _, passed) -> passed

pub fun bool_result(name : string, detail : string, passed : bool) : test_result
  Test_result(name, detail, passed)

pub fun maybe_text(target : maybe<string>) : string
  match target
    Just(name) -> name
    Nothing -> "<none>"

pub fun count_effects(xs : list<scheduled_effect>) : <div> int
  match xs
    Nil -> 0
    Cons(_, rest) -> 1 + count_effects(rest)

pub fun has_effect(path : string, xs : list<scheduled_effect>) : <div> bool
  match xs
    Nil -> False
    Cons(item, rest) -> if scheduled_effect_path(item) == path then True else has_effect(path, rest)

pub fun count_ints(xs : list<int>) : <div> int
  match xs
    Nil -> 0
    Cons(_, rest) -> 1 + count_ints(rest)

pub fun count_strings(xs : list<string>) : <div> int
  match xs
    Nil -> 0
    Cons(_, rest) -> 1 + count_strings(rest)

pub fun count_patches(xs : list<patch>) : <div> int
  match xs
    Nil -> 0
    Cons(_, rest) -> 1 + count_patches(rest)

pub fun count_patch_kind(xs : list<patch>, target_kind : string) : <div> int
  match xs
    Nil -> 0
    Cons(item, rest) -> (if patch_kind(item) == target_kind then 1 else 0) + count_patch_kind(rest, target_kind)

pub fun sum_ints(xs : list<int>) : <div> int
  match xs
    Nil -> 0
    Cons(head, rest) -> head + sum_ints(rest)

pub fun capture_waits(action : () -> <wait_ms|e> string) : e (string, list<int>)
  var waits := Nil
  with return(result) (result, waits)
  with fun wait_ms(delay) waits := Cons(delay, waits)
  action()

pub fun capture_workflow(action : () -> <wait_ms,fetch_lab_snapshot,post_lab_reply,now_label,audit,current_operator|e> model) : e (model, list<int>, list<string>)
  var waits := Nil
  var audits := Nil
  with return(result) (result, waits, audits)
  with val current_operator = "test-operator"
  with fun wait_ms(delay) waits := Cons(delay, waits)
  with fun fetch_lab_snapshot() mock_lab_snapshot()
  with fun post_lab_reply(incident_id, message) mock_lab_reply(incident_id, message)
  with fun now_label() "T+120"
  with fun audit(message) audits := Cons(message, audits)
  action()

pub fun passed_count(results : list<test_result>) : <div> int
  match results
    Nil -> 0
    Cons(item, rest) -> (if test_passed(item) then 1 else 0) + passed_count(rest)

pub fun total_count(results : list<test_result>) : <div> int
  match results
    Nil -> 0
    Cons(_, rest) -> 1 + total_count(rest)

pub fun find_result(name : string, results : list<test_result>) : <div> maybe<test_result>
  match results
    Nil -> Nothing
    Cons(item, rest) -> if test_name(item) == name then Just(item) else find_result(name, rest)