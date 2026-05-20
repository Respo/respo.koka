module demo/tests/dialogcases

import demo/dialogs
import demo/layout
import demo/model
import demo/tests/support
import respo/state

pub fun dialog_alert_open_test() : <div> test_result
  val (opened, audits) = capture_dialog_click(dialog_base_model(), dialog_open_payload("alert"))
  val current = opened.dialog
  Test_result(
    "Dialog alert opens overlay",
    "kind=" ++ current.kind.show_kind ++ ", title=" ++ current.title ++ ", audits=" ++ length(audits).show,
    (match current.kind { Dialog_alert -> True; _ -> False }) && current.title == "Alert demo" && length(audits) == 0)

pub fun dialog_prompt_validation_test() : <div> test_result
  val (opened, _open_audits) = capture_dialog_click(dialog_base_model(), dialog_open_payload("prompt"))
  val typed = match handle_dialog_input(dialog_prompt_channel(), "xy", opened)
    Just(result) -> result
    Nothing -> opened
  val (submitted, audits) = capture_dialog_click(typed, dialog_submit_payload())
  val current = submitted.dialog
  Test_result(
    "Dialog prompt validates input",
    "error=" ++ current.prompt_error ++ ", result=" ++ current.result_note ++ ", audits=" ++ length(audits).show,
    (match current.kind { Dialog_prompt -> True; _ -> False }) && current.prompt_error == "Use 3-8 characters." && length(audits) == 0)

pub fun dialog_prompt_submit_test() : <div> test_result
  val (opened, _open_audits) = capture_dialog_click(dialog_base_model(), dialog_open_payload("prompt"))
  val typed = match handle_dialog_input(dialog_prompt_channel(), "bridge", opened)
    Just(result) -> result
    Nothing -> opened
  val (submitted, audits) = capture_dialog_click(typed, dialog_submit_payload())
  val current = submitted.dialog
  Test_result(
    "Dialog prompt submits and closes",
    "kind=" ++ current.kind.show_kind ++ ", result=" ++ current.result_note ++ ", audits=" ++ length(audits).show,
    not(dialog_is_open(current)) && current.result_note == "Prompt submitted: bridge" && length(audits) == 1)

pub fun dialog_prompt_focus_effect_test() : <div> test_result
  val (opened, _open_audits) = capture_dialog_click(dialog_base_model(), dialog_open_payload("prompt"))
  val (_next_item, overlay_node, effects, _handlers) = render_layout(opened, Nil)
  Test_result(
    "Dialog prompt schedules focus effect",
    "effects=" ++ length(effects).show ++ ", marker=" ++ vnode_has_attr_value(overlay_node, "data-k-effect", "dialog-prompt-focus").show,
    any(effects, fn(item) scheduled_effect_path(item) == "dialog/focus/prompt") && vnode_has_attr_value(overlay_node, "data-k-effect", "dialog-prompt-focus"))

pub fun dialog_drawer_action_test() : <div> test_result
  val (opened, _open_audits) = capture_dialog_click(dialog_base_model(), dialog_open_payload("drawer"))
  val (closed, audits) = capture_dialog_click(opened, dialog_primary_payload())
  val opened_kind = opened.dialog.kind
  val current = closed.dialog
  Test_result(
    "Dialog drawer action closes overlay",
    "opened=" ++ opened_kind.show_kind ++ ", kind=" ++ current.kind.show_kind ++ ", result=" ++ current.result_note ++ ", audit=" ++ first_text(audits),
    (match opened_kind { Dialog_drawer -> True; _ -> False }) && not(dialog_is_open(current)) && current.result_note == "Drawer action completed." && first_text(audits) == "Drawer action completed.")