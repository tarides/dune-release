val with_out_file : string -> (out_channel -> 'a) -> 'a
val write : dir:string -> Caretaker.Project.t -> unit
val get_timesheets : lint:bool -> Common.t -> Caretaker.Report.t
val get_goals : org:string -> repo:string -> Caretaker.Issue.t list Lwt.t
val get_project : Common.t -> Caretaker.Project.t Lwt.t
