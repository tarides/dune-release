type t

val v :
  ?title:string ->
  ?objective:string ->
  ?status:string ->
  ?labels:string list ->
  ?team:string ->
  ?pillar:string ->
  ?assignees:string list ->
  ?quarter:string ->
  ?funder:string ->
  ?stakeholder:string ->
  ?size:string ->
  ?tracks:string list ->
  ?category:string ->
  ?other_fields:(string * string) list ->
  ?starts:string ->
  ?ends:string ->
  ?project_id:string ->
  ?card_id:string ->
  ?issue_id:string ->
  ?issue_url:string ->
  ?issue_closed:bool ->
  ?tracked_by:string ->
  string ->
  t

val id : t -> string
val card_id : t -> string
val issue_id : t -> string
val issue_url : t -> string
val issue_closed : t -> bool
val tracked_by : t -> string
val starts : t -> string
val ends : t -> string
val title : t -> string
val objective : t -> string
val status : t -> string
val funder : t -> string
val quarter : t -> string
val team : t -> string
val pillar : t -> string
val stakeholder : t -> string
val category : t -> string
val is_complete : t -> bool
val is_dropped : t -> bool
val should_be_open : t -> bool
val tracks : t -> string list

(* other stuff *)

val get_string : t -> Column.t -> string
val get_json : t -> Column.t -> Yojson.Safe.t
val other_fields : t -> (string * string) list
val graphql_query : string
val graphql_mutate : t -> Column.t -> string -> string
val pp : t Fmt.t
val to_csv : t -> string list
val csv_headers : string list

val parse_github_query :
  project_id:string -> fields:Fields.t -> Yojson.Safe.t -> t
(** Read from Github query *)

(** Filters *)

val matches : Filter.t -> t -> bool
val filter_out : Filter.t -> t list -> t list
val order_by : Column.t -> t list -> (string * t list) list

(** read from local data *)

val to_json : t -> Yojson.Safe.t
val of_json : project_id:string -> fields:Fields.t -> Yojson.Safe.t -> t

module Raw : sig
  val graphql_update :
    project_id:string ->
    card_id:string ->
    fields:Fields.t ->
    Column.t ->
    string ->
    string

  val add :
    Fields.t ->
    project_id:string ->
    issue_id:string ->
    (Column.t * string) list ->
    string Lwt.t

  val update :
    Fields.t ->
    project_id:string ->
    card_id:string ->
    (Column.t * string) list ->
    string Lwt.t
end
