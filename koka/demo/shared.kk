module demo/shared

import respo/core

pub fun panel(title : string, note : string, key : string, class_name : string, children : list<vnode>) : vnode
  el("section", key, [class_attr("panel " ++ class_name)], Nil, "", [
    el("h2", key ++ "-title", [class_attr("section-title")], Nil, title, Nil),
    el("p", key ++ "-note", [class_attr("section-note"), text_attr("data-k-effect", key ++ "-note")], Nil, note, Nil),
    el("div", key ++ "-body", [class_attr("stack")], Nil, "", children),
  ])

pub fun summary_chip(label : string, value : string) : vnode
  el("div", label, [class_attr("summary-chip")], Nil, "", [
    el("span", label ++ "-label", [class_attr("summary-label")], Nil, label, Nil),
    el("strong", label ++ "-value", [class_attr("summary-value")], Nil, value, Nil),
  ])
