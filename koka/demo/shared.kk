module demo/shared

import respo/core

pub fun panel(title : string, note : string, key : string, class_name : string, children : list<vnode>) : vnode
  node_class("section", key, "panel " ++ class_name, [
    text_class("h2", key ++ "-title", "section-title", title),
    text_node("p", key ++ "-note", props([class_attr("section-note"), text_attr("data-k-effect", key ++ "-note")], Nil), note),
    node_class("div", key ++ "-body", "stack", children),
  ])

pub fun summary_chip(label : string, value : string) : vnode
  node_class("div", label, "summary-chip", [
    text_class("span", label ++ "-label", "summary-label", label),
    text_class("strong", label ++ "-value", "summary-value", value),
  ])
