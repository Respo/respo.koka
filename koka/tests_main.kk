module tests_main

import demo/tests
import demo/tests/support

fun result_line(item : test_result) : string
  (if test_result/passed(item) then "[pass] " else "[fail] ") ++ test_result/name(item) ++ " - " ++ test_result/detail(item)

fun print_results(results : list<test_result>) : console ()
  match results
    Nil -> ()
    Cons(item, rest) ->
      println(result_line(item))
      print_results(rest)

fun main() : <console,div> ()
  print_results(demo_test_results())
