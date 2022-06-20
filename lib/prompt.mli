type answer = Yes | No

val confirm :
  question:('a, unit) Logs.msgf -> yes:bool -> default_answer:answer -> bool
(** Prompts the user for confirmation. [confirm ~question ~yes ~default_answer]
    uses the message formatting function [question] to format and log a message
    with the app level and wait for a yes or no answer from the user. Returns
    [true] for yes. Defaults to [default_answer] if the user just presses enter.
    If [yes], then it just skips the prompt and returns [true]. E.g.
    [confirm ~question:(fun l -> l "Do you want some %a?" Fmt.(styled `Bold
    string) "coffee")] *)

val confirm_or_abort :
  question:('a, unit) Logs.msgf ->
  yes:bool ->
  default_answer:answer ->
  (unit, Rresult.R.msg) result
(** Same as [confirm] but returns [Ok ()] for yes and
    [Error (`Msg "Aborting on user demand")] for no *)

val try_again :
  ?limit:int ->
  question:('a, unit) Logs.msgf ->
  yes:bool ->
  default_answer:answer ->
  (unit -> ('b, Rresult.R.msg) result) ->
  ('b, Rresult.R.msg) result
(** [try_again ?limit ~question ~yes ~default_answer f] prompts the user to try
    running [f] again if it failed, until [f] eventually succeeds or the user
    aborts the process by answering no or the maximum number of retries [limit]
    is reached (retries only once by default). *)

val user_input : ?default_answer:string -> question:string -> unit -> string
