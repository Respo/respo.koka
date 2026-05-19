module demo/effectspanel

import demo/model
import demo/tests/support
import demo/shared
import respo/core

fun render_tiny_items(tasks : list<task>) : <div> list<vnode>
  match tasks
    Nil -> Nil
    Cons(item, rest) -> Cons(text_node("li", "tiny-" ++ task_id(item).show, empty_props, task_title(item)), render_tiny_items(rest))

fun tiny_task_list(key : string, tasks : list<task>) : <div> vnode
  match tasks
    Nil -> text_class("p", key ++ "-empty", "empty", "None")
    Cons(_, _) -> node_class("ul", key, "tiny-list", render_tiny_items(tasks))

fun effect_case(title : string, detail : string, body : vnode) : vnode
  node_class("article", title, "case-item", [
    text_class("h3", title ++ "-title", "case-title", title),
    text_class("p", title ++ "-detail", "case-detail", detail),
    body,
  ])

fun case_detail(result_name : string, empty_key : string, detail_key : string, empty_text : string, results : list<test_result>) : <div> vnode
  match find(results, fn(item) test_result/name(item) == result_name)
    Nothing -> text_class("p", empty_key, "empty", empty_text)
    Just(item) -> text_class("p", detail_key, "mono", test_result/detail(item))

pub fun effects_panel(item : model, results : list<test_result>) : <div> vnode
  val active = tasks_for("active", model_tasks(item))
  val done = tasks_for("done", model_tasks(item))
  panel("Effects", "This route now shows where algebraic effects are actually pulling their weight: ambient values, timers, mocked server IO, and routeable workflow demos.", "effects", "effects-panel", [
    node_class("div", "cases", "case-grid", [
      effect_case("Confirm", "`confirm_action` is handled by the browser in app mode and by tests in-process.", text_class("p", "confirm-note", "mono", "Try Remove or Clear done in the todo panel.")),
      effect_case("Ambient filter", "The reducer stays unchanged while handlers project active or done subsets.", node_class("div", "ambient-preview", "preview-grid", [
        node_class("div", "active-preview", "mini-panel", [
          text_node("strong", "active-title", empty_props, "Active"),
          tiny_task_list("active-list", active),
        ]),
        node_class("div", "done-preview", "mini-panel", [
          text_node("strong", "done-title", empty_props, "Done"),
          tiny_task_list("done-list", done),
        ]),
      ])),
      effect_case("Workflow lab", "The richer demo composes `wait_ms`, mocked server fetch/send, and an ambient operator identity into one deterministic workflow.", case_detail("Workflow sync captures waits", "workflow-empty", "workflow-detail", "Workflow case unavailable.", results)),
      effect_case("Local state tree", "Per-card drafts and expand/collapse flags live in a keyed state tree instead of leaking into the main domain snapshot.", case_detail("State tree local state", "local-state-empty", "local-state-detail", "Local state case unavailable.", results)),
      effect_case("Timer", "`wait_ms` is handled without real time passing, so the case stays deterministic.", case_detail("Timer simulation", "timer-empty", "timer-detail", "Timer case unavailable.", results)),
    ]),
  ])
