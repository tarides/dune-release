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
