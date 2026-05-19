module demo/tests/dialogcases

import demo/dialogs
import demo/layout
import demo/model
import demo/tests/support
import respo/state

pub fun dialog_alert_open_test() : <div> test_result
  val (opened, audits) = capture_dialog_click(dialog_base_model(), dialog_open_payload("alert"))
  val current = model_dialog(opened)
  Test_result(
    "Dialog alert opens overlay",
    "kind=" ++ dialog_kind(current) ++ ", title=" ++ dialog_title(current) ++ ", audits=" ++ length(audits).show,
    dialog_kind(current) == "alert" && dialog_title(current) == "Alert demo" && length(audits) == 0)

pub fun dialog_prompt_validation_test() : <div> test_result
  val (opened, _open_audits) = capture_dialog_click(dialog_base_model(), dialog_open_payload("prompt"))
  val typed = match handle_dialog_input(dialog_prompt_channel(), "xy", opened)
    Just(result) -> result
    Nothing -> opened
  val (submitted, audits) = capture_dialog_click(typed, dialog_submit_payload())
  val current = model_dialog(submitted)
  Test_result(
    "Dialog prompt validates input",
    "error=" ++ dialog_prompt_error(current) ++ ", result=" ++ dialog_result_note(current) ++ ", audits=" ++ length(audits).show,
    dialog_kind(current) == "prompt" && dialog_prompt_error(current) == "Use 3-8 characters." && length(audits) == 0)

pub fun dialog_prompt_submit_test() : <div> test_result
  val (opened, _open_audits) = capture_dialog_click(dialog_base_model(), dialog_open_payload("prompt"))
  val typed = match handle_dialog_input(dialog_prompt_channel(), "bridge", opened)
    Just(result) -> result
    Nothing -> opened
  val (submitted, audits) = capture_dialog_click(typed, dialog_submit_payload())
  val current = model_dialog(submitted)
  Test_result(
    "Dialog prompt submits and closes",
    "kind=" ++ dialog_kind(current) ++ ", result=" ++ dialog_result_note(current) ++ ", audits=" ++ length(audits).show,
    not(dialog_is_open(current)) && dialog_result_note(current) == "Prompt submitted: bridge" && length(audits) == 1)

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
  val opened_kind = dialog_kind(model_dialog(opened))
  val current = model_dialog(closed)
  Test_result(
    "Dialog drawer action closes overlay",
    "opened=" ++ opened_kind ++ ", kind=" ++ dialog_kind(current) ++ ", result=" ++ dialog_result_note(current) ++ ", audit=" ++ first_text(audits),
    opened_kind == "drawer" && not(dialog_is_open(current)) && dialog_result_note(current) == "Drawer action completed." && first_text(audits) == "Drawer action completed.")