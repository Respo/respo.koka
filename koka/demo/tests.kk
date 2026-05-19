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
    registered_input_handler_test(),
    registered_click_handler_test(),
    timer_simulation_test(),
    state_tree_test(),
    generic_state_codec_test(),
    auto_hook_scope_test(),
    listener_registry_guard_test(),
    lab_local_routing_test(),
    add_task_focus_test(),
    start_edit_focus_test(),
    todo_edit_local_state_test(),
    todo_edit_diff_test(),
    workflow_sync_test(),
    workflow_reply_test(),
    bridge_pending_test(),
    bridge_resolve_test(),
    bridge_refresh_keeps_visible_test(),
    bridge_stale_shell_ignored_test(),
    bridge_stale_detail_ignored_test(),
    bridge_interleaved_old_detail_ignored_test(),
  ]
