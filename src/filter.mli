type query
type t = (Column.t * query) list

val is : string -> query
val is_not : string -> query
val starts_with : string -> query
val default_out : t
val eval : get:(Column.t -> string) -> t -> bool
