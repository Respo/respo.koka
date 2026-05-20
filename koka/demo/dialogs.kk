module demo/dialogs

import library/dialog
import demo/model
import respo/core
import respo/state

fun apply_dialog_update(owner : model, next_update : dialog_update) : model
  owner(dialog = next_update.dialog, notice = next_update.notice)

pub fun dialog_pending_effects(owner : model) : <div> list<scheduled_effect>
  dialog/dialog_pending_effects(owner.dialog)

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
  else if payload == dialog_close_payload() then
    Just(apply_dialog_update(owner, close_dialog(owner.dialog, "Overlay dismissed.", "Closed the overlay demo.", "[close] overlay dismissed")))
  else if payload == dialog_primary_payload() then
    Just(dialog_primary_action(owner))
  else if payload == dialog_submit_payload() then
    Just(prompt_submit(owner))
  else Nothing

pub fun handle_dialog_input(channel : string, value : string, owner : model) : <div> maybe<model>
  if channel == dialog_prompt_channel() then
    Just(owner(dialog = update_dialog_prompt(owner.dialog, value)))
  else Nothing

fun render_log_items(lines : list<string>) : <div> list<vnode>
  map-indexed(lines, fn(index, line) li_text_key("dialog-log-" ++ index.show, [class_attr("activity-item")], line))

pub fun dialog_demo_case(owner : model) : <div> vnode
  val current = owner.dialog
  div([class_attr("stack")], [
    div([class_attr("button-row")], [
      button([class_attr("button")], [click_listener(dialog_open_payload("alert"))], "Try Alert"),
      button([class_attr("button")], [click_listener(dialog_open_payload("prompt"))], "Try Prompt"),
      button([class_attr("button button-primary")], [click_listener(dialog_open_payload("dialog"))], "Try Dialog"),
      button([class_attr("button button-danger")], [click_listener(dialog_open_payload("drawer"))], "Try Drawer"),
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

fun prompt_body(current : dialog_demo) : <div> list<vnode>
  [
    input_text_key("dialog-prompt-input", [class_attr("input"), text_attr("data-k-effect", dialog_prompt_focus_marker())], [input_listener(dialog_prompt_channel()), enter_listener(dialog_submit_payload())], current.prompt_value, "3-8 chars"),
    if current.prompt_error == "" then p([class_attr("case-detail")], "Validation runs on submit, similar to the other Respo prompt demos.") else p([class_attr("dialog-error")], current.prompt_error),
  ]

fun dialog_custom_body(label : string, current : dialog_demo) : <div> list<vnode>
  [
    p([class_attr("case-detail")], current.message),
    div([class_attr("preview-grid")], [
      div([class_attr("mini-panel stack")], [
        strong(Nil, "Intentional layout"),
        p([class_attr("mono")], "The overlay is rendered globally, while actions still route through the same reducer/controller path."),
      ]),
      div([class_attr("mini-panel stack")], [
        strong(Nil, "Last result"),
        p([class_attr("mono")], current.result_note),
      ]),
    ]),
  ]

fun overlay_spec(current : dialog_demo) : <div> dialog_overlay_spec
  match current.kind
    Dialog_prompt -> Dialog_overlay_spec("dialog-overlay-shell dialog-overlay-center", "prompt-overlay", "dialog-overlay-card", prompt_body(current), Footer_submit("Submit"))
    Dialog_alert -> Dialog_overlay_spec("dialog-overlay-shell dialog-overlay-center", "alert-overlay", "dialog-overlay-card", [p([class_attr("case-detail")], "This alert is state-driven and lives inside the same VDOM tree as the rest of the app.")], Footer_primary_only("I read it"))
    Dialog_dialog -> Dialog_overlay_spec("dialog-overlay-shell dialog-overlay-center", "dialog-overlay", "dialog-overlay-card", dialog_custom_body("dialog-custom", current), Footer_primary_with_cancel("Run dialog action"))
    _ -> Dialog_overlay_spec("dialog-overlay-shell dialog-overlay-drawer", "drawer-overlay", "dialog-overlay-card drawer-overlay-card", dialog_custom_body("drawer-custom", current), Footer_primary_with_cancel("Commit drawer"))

pub fun render_dialog_overlay(owner : model) : <div> vnode
  dialog/render_dialog_overlay(owner.dialog, overlay_spec(owner.dialog))