module demo/tests

import demo/tests/support
import demo/tests/basics
import demo/tests/statecases
import demo/tests/todocases
import demo/tests/labcases

pub fun demo_test_results() : <div> list<test_result>
  [
    component_render_test(),
    confirm_decline_test(),
    confirm_accept_test(),
    ambient_filter_test(),
    timer_simulation_test(),
    state_tree_test(),
    generic_state_codec_test(),
    lab_local_routing_test(),
    add_task_focus_test(),
    start_edit_focus_test(),
    todo_edit_local_state_test(),
    todo_edit_diff_test(),
    workflow_sync_test(),
    workflow_reply_test(),
  ]
