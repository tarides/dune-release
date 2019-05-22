(** Promtps the user for confirmation.
    [confirm ~question] uses the message formatting function [question] to format and log
    a message with the app level and wait for a yes or no answer from the user.
    Returns [true] for yes. Defaults to yes if the user just press enter.
    E.g. [confirm ~question:(fun l -> l "Do you want some %a?" Fmt.(styled `Bold string) "coffee")] *)
val confirm : question: ('a, unit) Logs.msgf -> bool

(** Same as [confirm] but returns [Ok ()] for yes and [Error (`Msg "Aborting on user demand")] for
    no *)
val confirm_or_abort : question: ('a, unit) Logs.msgf -> (unit, Rresult.R.msg) result
