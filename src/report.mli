type item = { id : string; year : int; month : int; duration : float }
type t = (string, item) Hashtbl.t

val of_markdown : ?acc:t -> year:int -> month:int -> string -> t
val csv_headers : string list
val to_csv : t -> string
