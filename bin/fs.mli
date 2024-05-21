val read_file : string -> string
val write_file : string -> string -> unit
val write : dir:string -> Caretaker.Project.t -> unit

val get_timesheets :
  years:int list ->
  weeks:Caretaker.Weeks.t ->
  users:string list option ->
  ids:Caretaker.Filter.query list option ->
  lint:bool ->
  data_dir:string ->
  okr_updates_dir:string option ->
  admin_dir:string option ->
  Common.source ->
  Caretaker.Report.t

val get_goals : org:string -> repo:string -> Caretaker.Issue.t list Lwt.t

val get_project :
  ?items_per_page:int ->
  org:string ->
  goals:string ->
  project_number:int ->
  data_dir:string ->
  dry_run:bool ->
  Common.source ->
  Caretaker.Project.t Lwt.t
