module demo/view

import demo/model
import demo/tests/support
import demo/layout
import respo/core
import respo/state

pub fun render_app(item : model, results : list<test_result>) : <div> (model, vnode, list<scheduled_effect>, event_registry<model,browser_event_effect>)
  {
    val (_root_owner, (next_model, tree, layout_effects, layout_handlers), root_effects, root_handlers) = run_stateful_component(
      item,
      Nil,
      fn(owner, _next_tree) owner,
      fn(owner) component(component_local_path("app", "root"), fn() render_layout(owner, results)))
    (next_model, tree, append_scheduled_effects(layout_effects, root_effects), append_event_registries(root_handlers, layout_handlers))
  }


