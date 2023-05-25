type t

val v :
  title:string ->
  objective:string ->
  ?status:string ->
  ?team:string ->
  ?funders:string list ->
  ?schedule:string ->
  ?starts:string ->
  ?ends:string ->
  ?other_fields:(string * string) list ->
  string ->
  t

val id : t -> string
val get : t -> Column.t -> string
val other_fields : t -> (string * string) list
val graphql : string
val parse : Yojson.Safe.t -> t
val pp : t Fmt.t
val to_csv : t -> string list
val csv_headers : string list

(** Filters *)

val matches : Filter.t -> t -> bool
val filter_out : Filter.t -> t list -> t list
val order_by : Column.t -> t list -> (string * t list) list
