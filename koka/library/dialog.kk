module library/dialog

pub type dialog_kind
  Dialog_none
  Dialog_alert
  Dialog_prompt
  Dialog_dialog
  Dialog_drawer

pub fun show_kind(k : dialog_kind) : string
  match k
    Dialog_none -> "none"
    Dialog_alert -> "alert"
    Dialog_prompt -> "prompt"
    Dialog_dialog -> "dialog"
    Dialog_drawer -> "drawer"

pub struct dialog_demo
  kind : dialog_kind
  title : string
  message : string
  prompt_value : string
  prompt_error : string
  result_note : string
  activity_log : list<string>

pub fun initial_dialog_demo(result_note : string) : dialog_demo
  Dialog_demo(Dialog_none, "", "", "", "", result_note, Nil)

pub fun dialog_is_open(item : dialog_demo) : <div> bool
  match item.kind
    Dialog_none -> False
    _ -> True

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