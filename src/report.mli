type item = {
  id : string;
  year : int;
  month : int;
  week : int;
  user : string;
  days : float;
}

type t = (string, item) Hashtbl.t

val of_markdown : ?acc:t -> year:int -> week:int -> string -> t
val csv_headers : string list
val to_csv : t -> string
val of_csv : string -> t
