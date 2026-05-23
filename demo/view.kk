module demo/view

import demo/model
import demo/tests/support
import demo/layout
import explore/react/core
import explore/react/state

pub fun render_app(item : model, results : list<test_result>) : <div> (model, vnode, list<scheduled_effect>, event_registry<model,browser_event_effect>)
  flatten_component_run(run_stateful_component(
    item,
    Nil,
    fn(owner, _next_tree) owner,
    fn(owner) component(component_local_path("app", "root"), fn() render_layout(owner, results))))


