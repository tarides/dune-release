open Cmdliner

type source = Github | Okr_updates | Admin | Local

type t = {
  org : string;
  source : source;
  dry_run : bool;
  project_number : int;
  project_goals : string;
  items_per_page : int option;
  years : int list;
  weeks : Caretaker.Weeks.t;
  users : string list option;
  ids : Caretaker.Filter.query list option;
  data_dir : string;
  okr_updates_dir : string option;
  admin_dir : string option;
}

val term : default_source:source -> t Term.t
