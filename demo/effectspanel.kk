module demo/effectspanel

import demo/dialogs
import demo/model
import demo/tests/support
import demo/shared
import explore/react/core
import explore/react/state

alias effects_view_effect = <current_hook_scope_name,push_hook_scope,pop_hook_scope,register_listener<model,browser_event_effect>,div>

fun render_tiny_items(tasks : list<task>) : <div> list<vnode>
  map(tasks, fn(item) li_text_key("tiny-" ++ task/id(item).show, Nil, item.title))

fun tiny_task_list(key : string, tasks : list<task>) : <div> vnode
  if is-empty(tasks) then p([class_attr("empty")], "None") else ul_key(key, [class_attr("tiny-list")], render_tiny_items(tasks))

fun effect_case(title : string, detail : string, body : vnode) : vnode
  article_key(title, [class_attr("case-item")], [
    h3([class_attr("case-title")], title),
    p([class_attr("case-detail")], detail),
    body,
  ])

fun case_detail(result_name : string, empty_key : string, detail_key : string, empty_text : string, results : list<test_result>) : <div> vnode
  match find(results, fn(item) test_result/name(item) == result_name)
    Nothing -> p_key(empty_key, [class_attr("empty")], empty_text)
    Just(item) -> p_key(detail_key, [class_attr("mono")], test_result/detail(item))

fun core_effect_cases(item : model) : <div> list<vnode>
  val active = tasks_for("active", item.tasks)
  val done = tasks_for("done", item.tasks)
  [
    effect_case("Confirm", "`confirm_action` is handled by the browser in app mode and by tests in-process.", p([class_attr("mono")], "Try Remove or Clear done in the todo panel.")),
    effect_case("Ambient filter", "The reducer stays unchanged while handlers project active or done subsets.", div([class_attr("preview-grid")], [
      div([class_attr("mini-panel")], [
        strong(Nil, "Active"),
        tiny_task_list("active-list", active),
      ]),
      div([class_attr("mini-panel")], [
        strong(Nil, "Done"),
        tiny_task_list("done-list", done),
      ]),
    ])),
  ]

fun route_effect_cases(item : model, results : list<test_result>) : effects_view_effect list<vnode>
  if item.route_name == "effects-dialogs" then
    [effect_case("Dialog overlays", "Inspired by the MoonBit and Rust explore-react demos: trigger controlled alert, prompt, dialog, and drawer surfaces without leaving the app tree.", component(component_local_path("effects", "dialog-demo"), fn() dialog_demo_case(item)))]
  else if item.route_name == "effects-workflow" then
    [effect_case("Workflow lab", "The richer demo composes `wait_ms`, mocked server fetch/send, and an ambient operator identity into one deterministic workflow.", case_detail("Workflow sync captures waits", "workflow-empty", "workflow-detail", "Workflow case unavailable.", results))]
  else if item.route_name == "effects-state" then
    [effect_case("Local state tree", "Per-card drafts and expand/collapse flags live in a keyed state tree instead of leaking into the main domain snapshot.", case_detail("State tree local state", "local-state-empty", "local-state-detail", "Local state case unavailable.", results))]
  else if item.route_name == "effects-timer" then
    [effect_case("Timer", "`wait_ms` is handled without real time passing, so the case stays deterministic.", case_detail("Timer simulation", "timer-empty", "timer-detail", "Timer case unavailable.", results))]
  else
    core_effect_cases(item)

fun effects_panel_note(route_name : string) : string
  if route_name == "effects-dialogs" then "Dialog overlays get their own route so alert, prompt, dialog, and drawer interactions are no longer buried inside the broader effects overview."
  else if route_name == "effects-workflow" then "Workflow effects are isolated here so staged waits, mocked IO, and ambient operator state can be read without the other cases competing for attention."
  else if route_name == "effects-state" then "This route focuses on keyed local state, separate from domain data and remote workflow state."
  else if route_name == "effects-timer" then "Timer behavior stays deterministic because tests intercept `wait_ms` instead of waiting on wall-clock time."
  else "This route now shows the smaller effect cases that explain the core mechanics before the richer workflow and dialog demos branch off into their own subroutes."

pub fun effects_panel(item : model, results : list<test_result>) : effects_view_effect vnode
  val cases = route_effect_cases(item, results)
  panel("Effects", effects_panel_note(item.route_name), "effects", "effects-panel", [
    div([class_attr("case-grid")], cases),
  ])

pub fun run_effects_panel(item : model, results : list<test_result>) : <div> (model, vnode, list<scheduled_effect>, event_registry<model,browser_event_effect>)
  run_stateful_component(item, Nil, fn(owner, _next_tree) owner, fn(owner) effects_panel(owner, results))
