type t

val graphql : int -> string
val parse : Yojson.Safe.t -> t
val pp : ?order_by:Column.t -> ?filter_out:Filter.t -> t Fmt.t
val to_csv : t -> string
