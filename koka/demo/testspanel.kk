module demo/testspanel

import demo/tests/support
import demo/shared
import respo/core

fun test_item(item : test_result) : vnode
  val class_name = if test_passed(item) then "test-item test-pass" else "test-item test-fail"
  node_class("li", test_name(item), class_name, [
    text_node("strong", test_name(item) ++ "-name", empty_props, test_name(item)),
    text_class("p", test_name(item) ++ "-detail", "case-detail", test_detail(item)),
  ])

fun render_test_items(results : list<test_result>) : <div> list<vnode>
  match results
    Nil -> Nil
    Cons(item, rest) -> Cons(test_item(item), render_test_items(rest))

pub fun tests_panel(results : list<test_result>) : <div> vnode
  panel("Checks", passed_count(results).show ++ " / " ++ total_count(results).show ++ " pass in-process.", "tests", "tests-panel", [
    node_class("ul", "test-results", "test-list", render_test_items(results)),
  ])
