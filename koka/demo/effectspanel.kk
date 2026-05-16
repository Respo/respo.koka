module demo/effectspanel

import demo/model
import demo/tests
import demo/shared
import respo/core

fun render_tiny_items(tasks : list<task>) : <div> list<vnode>
  match tasks
    Nil -> Nil
    Cons(item, rest) -> Cons(el("li", "tiny-" ++ task_id(item).show, Nil, Nil, task_title(item), Nil), render_tiny_items(rest))

fun tiny_task_list(key : string, tasks : list<task>) : <div> vnode
  match tasks
    Nil -> el("p", key ++ "-empty", [class_attr("empty")], Nil, "None", Nil)
    Cons(_, _) -> el("ul", key, [class_attr("tiny-list")], Nil, "", render_tiny_items(tasks))

fun effect_case(title : string, detail : string, body : vnode) : vnode
  el("article", title, [class_attr("case-item")], Nil, "", [
    el("h3", title ++ "-title", [class_attr("case-title")], Nil, title, Nil),
    el("p", title ++ "-detail", [class_attr("case-detail")], Nil, detail, Nil),
    body,
  ])

fun timer_case(results : list<test_result>) : <div> vnode
  match find_result("Timer simulation", results)
    Nothing -> el("p", "timer-empty", [class_attr("empty")], Nil, "Timer case unavailable.", Nil)
    Just(item) -> el("p", "timer-detail", [class_attr("mono")], Nil, test_detail(item), Nil)

fun workflow_case(results : list<test_result>) : <div> vnode
  match find_result("Workflow sync captures waits", results)
    Nothing -> el("p", "workflow-empty", [class_attr("empty")], Nil, "Workflow case unavailable.", Nil)
    Just(item) -> el("p", "workflow-detail", [class_attr("mono")], Nil, test_detail(item), Nil)

fun local_state_case(results : list<test_result>) : <div> vnode
  match find_result("State tree local state", results)
    Nothing -> el("p", "local-state-empty", [class_attr("empty")], Nil, "Local state case unavailable.", Nil)
    Just(item) -> el("p", "local-state-detail", [class_attr("mono")], Nil, test_detail(item), Nil)

pub fun effects_panel(item : model, results : list<test_result>) : <div> vnode
  val active = tasks_for("active", model_tasks(item))
  val done = tasks_for("done", model_tasks(item))
  panel("Effects", "This route now shows where algebraic effects are actually pulling their weight: ambient values, timers, mocked server IO, and routeable workflow demos.", "effects", "effects-panel", [
    el("div", "cases", [class_attr("case-grid")], Nil, "", [
      effect_case("Confirm", "`confirm_action` is handled by the browser in app mode and by tests in-process.", el("p", "confirm-note", [class_attr("mono")], Nil, "Try Remove or Clear done in the todo panel.", Nil)),
      effect_case("Ambient filter", "The reducer stays unchanged while handlers project active or done subsets.", el("div", "ambient-preview", [class_attr("preview-grid")], Nil, "", [
        el("div", "active-preview", [class_attr("mini-panel")], Nil, "", [
          el("strong", "active-title", Nil, Nil, "Active", Nil),
          tiny_task_list("active-list", active),
        ]),
        el("div", "done-preview", [class_attr("mini-panel")], Nil, "", [
          el("strong", "done-title", Nil, Nil, "Done", Nil),
          tiny_task_list("done-list", done),
        ]),
      ])),
      effect_case("Workflow lab", "The richer demo composes `wait_ms`, mocked server fetch/send, and an ambient operator identity into one deterministic workflow.", workflow_case(results)),
      effect_case("Local state tree", "Per-card drafts and expand/collapse flags live in a keyed state tree instead of leaking into the main domain snapshot.", local_state_case(results)),
      effect_case("Timer", "`wait_ms` is handled without real time passing, so the case stays deterministic.", timer_case(results)),
    ]),
  ])
