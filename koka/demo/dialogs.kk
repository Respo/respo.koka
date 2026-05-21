module demo/dialogs

import library/dialog
import demo/model
import runtime/dom
import respo/core
import respo/state

alias dialog_view_effect = <current_hook_scope_name,push_hook_scope,pop_hook_scope,use_effect,register_listener<model,browser_event_effect>,div>
alias dialog_demo_effect = <current_hook_scope_name,register_listener<model,browser_event_effect>,div>

fun apply_dialog_update(owner : model, next_update : dialog_update) : <div> model
  val next_owner = owner(dialog = next_update.dialog, notice = next_update.notice)
  if owner.dialog.kind.show_kind == next_update.dialog.kind.show_kind then next_owner else next_owner(app_local_tree = clear_state_branch(next_owner.app_local_tree, component_local_path("overlays", "dialog")))

fun open_dialog_demo(owner : model, kind : dialog_kind, title : string, message : string, prompt_value : string, notice : string) : <div> model
  apply_dialog_update(owner, open_dialog(owner.dialog, kind, title, message, prompt_value, notice))

fun apply_audited_update(owner : model, next_update : dialog_update) : <audit,div> model
  match next_update.audit_message
    Just(message) -> {
      audit(message)
      apply_dialog_update(owner, next_update)
    }
    Nothing -> apply_dialog_update(owner, next_update)

fun prompt_submit(owner : model) : <audit,div> model
  apply_audited_update(owner, submit_dialog_prompt(owner.dialog, "Prompt dialog submitted through the overlay demo."))

fun dialog_primary_action(owner : model) : <audit,div> model
  val current = owner.dialog
  match current.kind
    Dialog_alert -> apply_audited_update(owner, resolve_dialog_primary(current, "Alert acknowledged.", "Alert overlay acknowledged.", "[ack] alert overlay", "Alert acknowledged."))
    Dialog_dialog -> apply_audited_update(owner, resolve_dialog_primary(current, "Dialog action completed.", "Dialog overlay primary action completed.", "[accept] dialog overlay", "Dialog action completed."))
    Dialog_drawer -> apply_audited_update(owner, resolve_dialog_primary(current, "Drawer action completed.", "Drawer overlay primary action completed.", "[accept] drawer overlay", "Drawer action completed."))
    _ -> owner

pub fun handle_dialog_click(payload : string, owner : model) : <audit,div> maybe<model>
  if payload == dialog_open_payload("alert") then
    Just(open_dialog_demo(owner, Dialog_alert, "Alert demo", "A controlled alert surface rendered inside the app tree, similar to the Respo demos in the MoonBit and Rust implementations.", "", "Opened alert overlay demo."))
  else if payload == dialog_open_payload("prompt") then
    Just(open_dialog_demo(owner, Dialog_prompt, "Prompt demo", "Type 3-8 characters. This mimics a controlled prompt instead of delegating to a native browser API.", "respo", "Opened prompt overlay demo."))
  else if payload == dialog_open_payload("dialog") then
    Just(open_dialog_demo(owner, Dialog_dialog, "Dialog demo", "This is a centered custom dialog body, closer to a React/Respo modal component than a native browser API.", "", "Opened dialog overlay demo."))
  else if payload == dialog_open_payload("drawer") then
    Just(open_dialog_demo(owner, Dialog_drawer, "Drawer demo", "This side sheet keeps the background visible while secondary actions happen in a dedicated panel.", "", "Opened drawer overlay demo."))
  else Nothing

fun render_log_items(lines : list<string>) : <div> list<vnode>
  map-indexed(lines, fn(index, line) li_text_key("dialog-log-" ++ index.show, [class_attr("activity-item")], line))

pub fun dialog_demo_case(owner : model) : dialog_demo_effect vnode
  val current = owner.dialog
  val open_alert = on_local_click("open-alert", fn(next_owner : model) open_dialog_demo(next_owner, Dialog_alert, "Alert demo", "A controlled alert surface rendered inside the app tree, similar to the Respo demos in the MoonBit and Rust implementations.", "", "Opened alert overlay demo."))
  val open_prompt = on_local_click("open-prompt", fn(next_owner : model) open_dialog_demo(next_owner, Dialog_prompt, "Prompt demo", "Type 3-8 characters. This mimics a controlled prompt instead of delegating to a native browser API.", "respo", "Opened prompt overlay demo."))
  val open_dialog_listener = on_local_click("open-dialog", fn(next_owner : model) open_dialog_demo(next_owner, Dialog_dialog, "Dialog demo", "This is a centered custom dialog body, closer to a React/Respo modal component than a native browser API.", "", "Opened dialog overlay demo."))
  val open_drawer = on_local_click("open-drawer", fn(next_owner : model) open_dialog_demo(next_owner, Dialog_drawer, "Drawer demo", "This side sheet keeps the background visible while secondary actions happen in a dedicated panel.", "", "Opened drawer overlay demo."))
  div([class_attr("stack")], [
    div([class_attr("button-row")], [
      button([class_attr("button")], [open_alert], "Try Alert"),
      button([class_attr("button")], [open_prompt], "Try Prompt"),
      button([class_attr("button button-primary")], [open_dialog_listener], "Try Dialog"),
      button([class_attr("button button-danger")], [open_drawer], "Try Drawer"),
    ]),
    div([class_attr("preview-grid")], [
      div([class_attr("mini-panel stack")], [
        strong(Nil, "Overlay state"),
        p([class_attr("mono")], "kind: " ++ (if dialog_is_open(current) then current.kind.show_kind else "<none>")),
        p([class_attr("mono")], "result: " ++ current.result_note),
      ]),
      div([class_attr("mini-panel stack")], [
        strong(Nil, "Dialog activity"),
        if is-empty(current.activity_log) then p([class_attr("empty")], "No overlay interactions yet.") else ul([class_attr("activity-list dialog-log-list")], render_log_items(current.activity_log)),
      ]),
    ]),
  ])

fun prompt_body(current : dialog_demo, prompt_input_listener : listener, submit_enter_listener : listener) : <div> list<vnode>
  [
    input_text_key("dialog-prompt-input", [class_attr("input"), text_attr("data-k-effect", dialog_prompt_focus_marker())], [prompt_input_listener, submit_enter_listener], current.prompt_value, "3-8 chars"),
    if current.prompt_error == "" then p([class_attr("case-detail")], "Validation runs on submit, similar to the other Respo prompt demos.") else p([class_attr("dialog-error")], current.prompt_error),
  ]

fun dialog_custom_body(label : string, current : dialog_demo) : <div> list<vnode>
  [
    p([class_attr("case-detail")], current.message),
    div([class_attr("preview-grid")], [
      div([class_attr("mini-panel stack")], [
        strong(Nil, "Intentional layout"),
        p([class_attr("mono")], "The dialog demo keeps open and overlay actions inside local listeners, even though the overlay still renders globally in the app tree."),
      ]),
      div([class_attr("mini-panel stack")], [
        strong(Nil, "Last result"),
        p([class_attr("mono")], current.result_note),
      ]),
    ]),
  ]

fun overlay_spec(current : dialog_demo, prompt_input_listener : listener, submit_enter_listener : listener) : <div> dialog_overlay_spec
  match current.kind
    Dialog_prompt -> Dialog_overlay_spec("dialog-overlay-shell dialog-overlay-center", "prompt-overlay", "dialog-overlay-card", prompt_body(current, prompt_input_listener, submit_enter_listener), Footer_submit("Submit"))
    Dialog_alert -> Dialog_overlay_spec("dialog-overlay-shell dialog-overlay-center", "alert-overlay", "dialog-overlay-card", [p([class_attr("case-detail")], "This alert is state-driven and lives inside the same VDOM tree as the rest of the app.")], Footer_primary_only("I read it"))
    Dialog_dialog -> Dialog_overlay_spec("dialog-overlay-shell dialog-overlay-center", "dialog-overlay", "dialog-overlay-card", dialog_custom_body("dialog-custom", current), Footer_primary_with_cancel("Run dialog action"))
    _ -> Dialog_overlay_spec("dialog-overlay-shell dialog-overlay-drawer", "drawer-overlay", "dialog-overlay-card drawer-overlay-card", dialog_custom_body("drawer-custom", current), Footer_primary_with_cancel("Commit drawer"))

pub fun dialog_overlay_effect_path() : string
  component_hook_effect_path("overlays", "dialog", 0)

pub fun render_dialog_overlay(owner : model) : dialog_view_effect vnode
  component(component_local_path("overlays", "dialog"), fn() {
    val current = owner.dialog
    val close_overlay = on_local_click("close-overlay", fn(next_owner : model) apply_dialog_update(next_owner, close_dialog(next_owner.dialog, "Overlay dismissed.", "Closed the overlay demo.", "[close] overlay dismissed")))
    val primary_action = on_local_click("primary-action", fn(next_owner : model) dialog_primary_action(next_owner))
    val submit_action = on_local_click("submit-action", fn(next_owner : model) prompt_submit(next_owner))
    val submit_enter = on_local_enter("submit-action", fn(next_owner : model) prompt_submit(next_owner))
    val prompt_input = on_local_input("prompt-input", fn(value, next_owner : model) next_owner(dialog = update_dialog_prompt(next_owner.dialog, value)))
    use_effect([current.kind.show_kind, current.prompt_error, current.title], fn() {
      if dialog_is_open(current) then dom_focus(dialog_focus_marker(current)) else ()
    })
    dialog/render_dialog_overlay(current, overlay_spec(current, prompt_input, submit_enter), Dialog_overlay_controls(close_overlay, primary_action, submit_action))
  })

pub fun run_dialog_overlay(owner : model) : <div> (model, vnode, list<scheduled_effect>, event_registry<model,browser_event_effect>)
  run_stateful_component(
    owner,
    owner.app_local_tree,
    fn(next_owner, next_tree) next_owner(app_local_tree = next_tree),
    fn(next_owner) render_dialog_overlay(next_owner))