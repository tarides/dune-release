(** App level logs with distinct headers based on the nature of the message *)

val status : ?src:Logs.src -> 'a Logs.log
(** For informative messages about what's currently happening such as
    ["doing this"] *)

val question : ?src:Logs.src -> 'a Logs.log
(** For prompts *)

val success : ?src:Logs.src -> 'a Logs.log
(** To report successfully completed tasks *)

val unhappy : ?src:Logs.src -> 'a Logs.log
(** To report something that went wrong but isn't worth a warning *)

val blank_line : unit -> unit
(** Outpus an empty line *)

(** Check logs *)

val report_status :
  [ `Fail | `Ok ] ->
  ((?header:string ->
   ?tags:Logs.Tag.set ->
   ('a, Format.formatter, unit) format ->
   'a) ->
  unit) ->
  unit
(** To report one check of a list of checks. [report st f] is formatted as "\[
    status\] more_information", where status and more_information are specified
    by st and f, respectively *)
