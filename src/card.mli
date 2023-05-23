type t

val id : t -> string
val get : t -> Column.t -> string
val other_fields : t -> (string * string) list
val graphql : string
val parse : Yojson.Safe.t -> t
val pp : t Fmt.t
val to_csv : t -> string list
val csv_headers : string list

(** Filters *)

val filter_out : Filter.t -> t -> bool
