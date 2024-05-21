open Cmdliner

type source = Github | Okr_updates | Admin | Local

val org_term : string Term.t
val source_term : source -> source Term.t
val dry_run_term : bool Term.t
val project_number_term : int Term.t
val project_goals_term : string Term.t
val items_per_page : int option Term.t
val years : int list Term.t
val weeks : Caretaker.Weeks.t Term.t
val users : string list option Term.t
val ids : Caretaker.Filter.query list option Term.t
val data_dir_term : string Term.t
val okr_updates_dir_term : string option Term.t
val admin_dir_term : string option Term.t
val setup : unit Term.t
