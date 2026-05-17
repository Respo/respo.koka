module demo/testspanel

import demo/tests/support
import demo/shared
import respo/core

fun test_item(item : test_result) : vnode
  val class_name = if test_passed(item) then "test-item test-pass" else "test-item test-fail"
  el("li", test_name(item), [class_attr(class_name)], Nil, "", [
    el("strong", test_name(item) ++ "-name", Nil, Nil, test_name(item), Nil),
    el("p", test_name(item) ++ "-detail", [class_attr("case-detail")], Nil, test_detail(item), Nil),
  ])

fun render_test_items(results : list<test_result>) : <div> list<vnode>
  match results
    Nil -> Nil
    Cons(item, rest) -> Cons(test_item(item), render_test_items(rest))

pub fun tests_panel(results : list<test_result>) : <div> vnode
  panel("Checks", passed_count(results).show ++ " / " ++ total_count(results).show ++ " pass in-process.", "tests", "tests-panel", [
    el("ul", "test-results", [class_attr("test-list")], Nil, "", render_test_items(results)),
  ])
