module demo/dialogs

import demo/model
import runtime/dom
import respo/core
import respo/state

fun append_dialog_attrs(left : list<attr>, right : list<attr>) : <div> list<attr>
  match left
    Nil -> right
    Cons(head, rest) -> Cons(head, append_dialog_attrs(rest, right))

pub fun dialog_open_payload(kind : string) : string
  "dialog-open-" ++ kind

pub fun dialog_close_payload() : string
  "dialog-close"

pub fun dialog_primary_payload() : string
  "dialog-primary"

pub fun dialog_submit_payload() : string
  "dialog-submit"

pub fun dialog_prompt_channel() : string
  "dialog-prompt"

fun dialog_dismiss_attr() : attr
  text_attr("data-k-dialog-dismiss", "true")

fun dialog_shell_attrs(current : dialog_demo) : list<attr>
  [
    text_attr("data-k-dialog-shell", "true"),
    text_attr("data-k-dialog-surface", match current.kind { Dialog_drawer -> "drawer"; _ -> "modal" }),
    text_attr("data-k-dialog-close", dialog_close_payload()),
  ]

fun dialog_primary_focus_marker() : string
  "dialog-primary-focus"

fun dialog_prompt_focus_marker() : string
  "dialog-prompt-focus"

fun dialog_focus_marker(current : dialog_demo) : string
  match current.kind
    Dialog_prompt -> dialog_prompt_focus_marker()
    _ -> dialog_primary_focus_marker()

pub fun dialog_pending_effects(owner : model) : <div> list<scheduled_effect>
  val current = owner.dialog
  if dialog_is_open(current) then
    [Scheduled_effect("dialog/focus/" ++ current.kind.show_kind, fn(root_id) browser_focus(root_id, dialog_focus_marker(current)))]
  else Nil

fun dialog_button(key : string, class_name : string, marker : string, listeners : list<listener>, label : string) : vnode
  text_node("button", key, props([class_attr(class_name), text_attr("data-k-effect", marker)], listeners), label)

fun dismiss_button(key : string, class_name : string, marker : maybe<string>, payload : string, label : string) : vnode
  val attrs = match marker
    Just(found) -> [class_attr(class_name), text_attr("data-k-effect", found), dialog_dismiss_attr()]
    Nothing -> [class_attr(class_name), dialog_dismiss_attr()]
  text_node("button", key, props(attrs, [click_listener(payload)]), label)

fun dismiss_backdrop(current : dialog_demo) : <div> vnode
  node("div", "dialog-backdrop", props(append_dialog_attrs([class_attr("dialog-backdrop")], [dialog_dismiss_attr()]), [click_listener(dialog_close_payload())]), Nil)

fun append_dialog_log(lines : list<string>, value : string) : <div> list<string>
  lines ++ [value]

fun set_dialog_result(owner : model, note : string, line : string) : <div> model
  val current = owner.dialog
  val next_dialog = current(
    kind = Dialog_none,
    title = "",
    message = "",
    prompt_value = "",
    prompt_error = "",
    result_note = note,
    activity_log = append_dialog_log(current.activity_log, line))
  owner(dialog = next_dialog)

fun open_dialog_demo(owner : model, kind : dialog_kind, title : string, message : string, prompt_value : string, notice : string) : <div> model
  val current = owner.dialog
  val next_dialog = current(
    kind = kind,
    title = title,
    message = message,
    prompt_value = prompt_value,
    prompt_error = "",
    activity_log = append_dialog_log(current.activity_log, "[open] " ++ title))
  owner(dialog = next_dialog, notice = notice)

fun validate_prompt(value : string) : <div> maybe<string>
  val trimmed = trim(value)
  val size = chars/count(trimmed)
  if size < 3 then Just("Use 3-8 characters.")
  else if size > 8 then Just("Keep the prompt within 8 characters.")
  else Nothing

fun prompt_submit(owner : model) : <audit,div> model
  val current = owner.dialog
  val trimmed = trim(current.prompt_value)
  match validate_prompt(trimmed)
    Just(message) -> owner(dialog = current(prompt_error = message), notice = message)
    Nothing -> {
      audit("Prompt submitted: " ++ trimmed)
      set_dialog_result(owner, "Prompt submitted: " ++ trimmed, "[submit] prompt => " ++ trimmed)(notice = "Prompt dialog submitted through the overlay demo.")
    }

fun dialog_primary_action(owner : model) : <audit,div> model
  val current = owner.dialog
  match current.kind
    Dialog_alert -> {
      audit("Alert acknowledged.")
      set_dialog_result(owner, "Alert acknowledged.", "[ack] alert overlay")(notice = "Alert overlay acknowledged.")
    }
    Dialog_dialog -> {
      audit("Dialog action completed.")
      set_dialog_result(owner, "Dialog action completed.", "[accept] dialog overlay")(notice = "Dialog overlay primary action completed.")
    }
    Dialog_drawer -> {
      audit("Drawer action completed.")
      set_dialog_result(owner, "Drawer action completed.", "[accept] drawer overlay")(notice = "Drawer overlay primary action completed.")
    }
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
    Just(set_dialog_result(owner, "Overlay dismissed.", "[close] overlay dismissed")(notice = "Closed the overlay demo."))
  else if payload == dialog_primary_payload() then
    Just(dialog_primary_action(owner))
  else if payload == dialog_submit_payload() then
    Just(prompt_submit(owner))
  else Nothing

pub fun handle_dialog_input(channel : string, value : string, owner : model) : <div> maybe<model>
  if channel == dialog_prompt_channel() then
    val current = owner.dialog
    Just(owner(dialog = current(prompt_value = value, prompt_error = "")))
  else Nothing

fun render_log_items(lines : list<string>) : <div> list<vnode>
  map-indexed(lines, fn(index, line) text_class("li", "dialog-log-" ++ index.show, "activity-item", line))

pub fun dialog_demo_case(owner : model) : <div> vnode
  val current = owner.dialog
  node_class("div", "dialog-demo", "stack", [
    node_class("div", "dialog-demo-actions", "button-row", [
      button_class("try-alert", "button", [click_listener(dialog_open_payload("alert"))], "Try Alert"),
      button_class("try-prompt", "button", [click_listener(dialog_open_payload("prompt"))], "Try Prompt"),
      button_class("try-dialog", "button button-primary", [click_listener(dialog_open_payload("dialog"))], "Try Dialog"),
      button_class("try-drawer", "button button-danger", [click_listener(dialog_open_payload("drawer"))], "Try Drawer"),
    ]),
    node_class("div", "dialog-demo-preview", "preview-grid", [
      node_class("div", "dialog-demo-summary", "mini-panel stack", [
        text_node("strong", "dialog-demo-summary-title", empty_props, "Overlay state"),
        text_class("p", "dialog-demo-kind", "mono", "kind: " ++ (if dialog_is_open(current) then current.kind.show_kind else "<none>")),
        text_class("p", "dialog-demo-result", "mono", "result: " ++ current.result_note),
      ]),
      node_class("div", "dialog-demo-log", "mini-panel stack", [
        text_node("strong", "dialog-demo-log-title", empty_props, "Dialog activity"),
        if is-empty(current.activity_log) then text_class("p", "dialog-demo-log-empty", "empty", "No overlay interactions yet.") else node_class("ul", "dialog-demo-log-list", "activity-list dialog-log-list", render_log_items(current.activity_log)),
      ]),
    ]),
  ])

fun dialog_header(current : dialog_demo) : <div> vnode
  node_class("div", "dialog-header", "dialog-header", [
    node_class("div", "dialog-header-copy", "stack", [
      text_class("strong", "dialog-title", "section-title", current.title),
      text_class("p", "dialog-message", "case-detail", current.message),
    ]),
    dismiss_button("dialog-close-top", "button", Nothing, dialog_close_payload(), "Close"),
  ])

fun prompt_body(current : dialog_demo) : <div> list<vnode>
  [
    text_input("dialog-prompt-input", "input", current.prompt_value, "3-8 chars", [text_attr("data-k-effect", dialog_prompt_focus_marker())], [input_listener(dialog_prompt_channel()), enter_listener(dialog_submit_payload())]),
    if current.prompt_error == "" then text_class("p", "dialog-prompt-note", "case-detail", "Validation runs on submit, similar to the other Respo prompt demos.") else text_class("p", "dialog-prompt-error", "dialog-error", current.prompt_error),
  ]

fun dialog_custom_body(label : string, current : dialog_demo) : <div> list<vnode>
  [
    text_class("p", label ++ "-note", "case-detail", current.message),
    node_class("div", label ++ "-grid", "preview-grid", [
      node_class("div", label ++ "-left", "mini-panel stack", [
        text_node("strong", label ++ "-left-title", empty_props, "Intentional layout"),
        text_class("p", label ++ "-left-copy", "mono", "The overlay is rendered globally, while actions still route through the same reducer/controller path."),
      ]),
      node_class("div", label ++ "-right", "mini-panel stack", [
        text_node("strong", label ++ "-right-title", empty_props, "Last result"),
        text_class("p", label ++ "-right-copy", "mono", current.result_note),
      ]),
    ]),
  ]

fun dialog_actions(current : dialog_demo) : <div> vnode
  match current.kind
    Dialog_prompt ->
      node_class("div", "dialog-actions", "button-row dialog-actions", [
        dismiss_button("dialog-cancel", "button", Nothing, dialog_close_payload(), "Cancel"),
        button_class("dialog-submit", "button button-primary", [click_listener(dialog_submit_payload())], "Submit"),
      ])
    Dialog_alert ->
      node_class("div", "dialog-actions", "button-row dialog-actions", [
        dismiss_button("dialog-alert-read", "button button-primary dialog-primary-button", Just(dialog_primary_focus_marker()), dialog_primary_payload(), "I read it"),
      ])
    Dialog_drawer ->
      node_class("div", "dialog-actions", "button-row dialog-actions", [
        dismiss_button("dialog-cancel", "button", Nothing, dialog_close_payload(), "Cancel"),
        dismiss_button("dialog-primary", "button button-primary dialog-primary-button", Just(dialog_primary_focus_marker()), dialog_primary_payload(), "Commit drawer"),
      ])
    _ ->
      node_class("div", "dialog-actions", "button-row dialog-actions", [
        dismiss_button("dialog-cancel", "button", Nothing, dialog_close_payload(), "Cancel"),
        dismiss_button("dialog-primary", "button button-primary dialog-primary-button", Just(dialog_primary_focus_marker()), dialog_primary_payload(), "Run dialog action"),
      ])

fun overlay_card(key : string, class_name : string, current : dialog_demo, body_children : list<vnode>) : <div> vnode
  node_class("article", key, class_name, [
    dialog_header(current),
    node_class("div", key ++ "-body", "dialog-panel-body", body_children),
    dialog_actions(current),
  ])

pub fun render_dialog_overlay(owner : model) : <div> vnode
  val current = owner.dialog
  match current.kind
    Dialog_prompt ->
      node("section", "dialog-overlay", props(append_dialog_attrs([class_attr("dialog-overlay-shell dialog-overlay-center")], dialog_shell_attrs(current)), Nil), [
        dismiss_backdrop(current),
        overlay_card("prompt-overlay", "dialog-overlay-card", current, prompt_body(current)),
      ])
    Dialog_alert ->
      node("section", "dialog-overlay", props(append_dialog_attrs([class_attr("dialog-overlay-shell dialog-overlay-center")], dialog_shell_attrs(current)), Nil), [
        dismiss_backdrop(current),
        overlay_card("alert-overlay", "dialog-overlay-card", current, [text_class("p", "alert-note", "case-detail", "This alert is state-driven and lives inside the same VDOM tree as the rest of the app.")]),
      ])
    Dialog_dialog ->
      node("section", "dialog-overlay", props(append_dialog_attrs([class_attr("dialog-overlay-shell dialog-overlay-center")], dialog_shell_attrs(current)), Nil), [
        dismiss_backdrop(current),
        overlay_card("dialog-overlay", "dialog-overlay-card", current, dialog_custom_body("dialog-custom", current)),
      ])
    _ ->
      node("section", "drawer-overlay", props(append_dialog_attrs([class_attr("dialog-overlay-shell dialog-overlay-drawer")], dialog_shell_attrs(current)), Nil), [
        dismiss_backdrop(current),
        overlay_card("drawer-overlay", "dialog-overlay-card drawer-overlay-card", current, dialog_custom_body("drawer-custom", current)),
      ])