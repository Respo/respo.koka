module demo/tests/statecases

import demo/tests/support
import respo/state

pub fun state_tree_test() : <div> test_result
  val incident_base = "lab/incidents/101"
  val draft_slot = slot(incident_base, 0)
  val expanded_slot = named_slot(incident_base, "expanded")
  val tree = assoc_slot_flag(assoc_slot_text(Nil, draft_slot, "Shift traffic to backup POP."), expanded_slot, True)
  val draft = slot_text(tree, draft_slot, "")
  val expanded = slot_flag(tree, expanded_slot, False)
  val normalized_name = state_slot_path(named_slot("todo/tasks/2", "7draft"))
  bool_result("State tree local state", "draft=" ++ draft ++ ", expanded=" ++ expanded.show ++ ", named=" ++ normalized_name, draft == "Shift traffic to backup POP." && expanded && normalized_name == "todo/tasks/2/_7draft")

pub fun generic_state_codec_test() : <div> test_result
  val draft_slot = named_slot("generic-test", "draft")
  val open_slot = named_slot("generic-test", "open")
  val ((draft, open_before), next_tree, _pending_effects) = run_local_state(Nil, fn() {
    val draft0 = use_state(draft_slot, text_state_codec, "hello")
    val open0 = use_state(open_slot, flag_state_codec, False)
    set_state(draft_slot, text_state_codec, draft0 ++ " world")
    set_state(open_slot, flag_state_codec, not(open0))
    (draft0, open0)
  })
  val draft_after = slot_text(next_tree, draft_slot, "")
  val open_after = slot_flag(next_tree, open_slot, False)
  bool_result("Generic use_state codec", "draft=" ++ draft ++ ", open-before=" ++ open_before.show ++ ", open-after=" ++ open_after.show, draft == "hello" && not(open_before) && draft_after == "hello world" && open_after)