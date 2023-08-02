type t

val v :
  ?title:string ->
  ?cards:Card.t list ->
  ?project_id:string ->
  ?goals:Issue.t list ->
  string ->
  int ->
  t

val empty : t
val org : t -> string
val number : t -> int
val pp : ?order_by:Column.t -> ?filter_out:Filter.t -> t Fmt.t
val to_csv : t -> string
val filter : ?filter_out:Filter.t -> t -> t
val sync : ?heatmap:Heatmap.t -> t -> unit Lwt.t
val lint : ?heatmap:Heatmap.t -> t -> unit
val cards : t -> Card.t list
val project_id : t -> string
val fields : t -> Fields.t

(** Local dumps *)

val to_json : t -> Yojson.Safe.t
val of_json : Yojson.Safe.t -> t

(** Queries *)

val get :
  goals:Issue.t list -> org:string -> project_number:int -> unit -> t Lwt.t

val get_project_id_and_fields :
  org:string -> project_number:int -> (string * Fields.t) Lwt.t
