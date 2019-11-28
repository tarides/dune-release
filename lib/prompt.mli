val confirm : question:('a, unit) Logs.msgf -> yes:bool -> bool
(** Promtps the user for confirmation. [confirm ~question ~yes] uses the message
    formatting function [question] to format and log a message with the app
    level and wait for a yes or no answer from the user. Returns [true] for yes.
    Defaults to yes if the user just press enter. If [yes] then just skip the
    prompt and returns [true]. E.g.
    [confirm ~question:(fun l -> l "Do you want some %a?" Fmt.(styled `Bold
    string) "coffee")] *)

val confirm_or_abort :
  ?skippable:(unit -> (unit, Rresult.R.msg) result) ->
  question:('a, unit) Logs.msgf ->
  yes:bool ->
  unit ->
  (unit, Rresult.R.msg) result
(** Same as [confirm] but the confirmed part can be skippable:

    - If the user chooses [yes], the [skippable] function is executed and
      returned, if the treatment is not skippable ([skippable] is not set),
      returns [Ok ()];
    - If the user chooses [skip], returns [Ok ()] and does not execute the
      [skippable] function;
    - If the user chooses [no], returns an error message. *)
