type query = private Is of string | Starts_with of string
type t = (Column.t * query) list

val is : string -> query
val starts_with : string -> query
val default_out : t
