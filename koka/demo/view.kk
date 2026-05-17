module demo/view

import demo/model
import demo/tests/support
import demo/layout
import respo/core
import respo/state

pub fun render_app(item : model, results : list<test_result>) : <div> (model, vnode, list<scheduled_effect>)
  render_layout(item, results)


