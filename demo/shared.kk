module demo/shared

import explore/react/core

pub fun panel(title : string, note : string, key : string, class_name : string, children : list<vnode>) : vnode
  section_key(key, [class_attr("panel " ++ class_name)], [
    h2([class_attr("section-title")], title),
    p_key(key ++ "-note", [class_attr("section-note"), text_attr("data-k-effect", key ++ "-note")], note),
    div([class_attr("stack")], children),
  ])

pub fun summary_chip(label : string, value : string) : vnode
  div([class_attr("summary-chip")], [
    span([class_attr("summary-label")], label),
    strong([class_attr("summary-value")], value),
  ])
