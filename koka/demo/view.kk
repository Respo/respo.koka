module demo/view

import demo/model
import demo/tests/support
import demo/layout
import respo/core

pub fun render_app(item : model, results : list<test_result>) : <div> vnode
  render_layout(item, results)


