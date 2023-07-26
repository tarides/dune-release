type query
type t = (Column.t * query) list

val is : string -> query
val not : query -> query
val starts_with : string -> query
val default_out : t
val eval : get:(Column.t -> string) -> t -> bool
val query : string -> query
