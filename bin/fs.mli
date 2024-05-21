val read_file : string -> string
val write_file : string -> string -> unit
val write : dir:string -> Caretaker.Project.t -> unit
val get_timesheets : lint:bool -> Common.t -> Caretaker.Report.t
val get_goals : org:string -> repo:string -> Caretaker.Issue.t list Lwt.t
val get_project : Common.t -> Caretaker.Project.t Lwt.t
