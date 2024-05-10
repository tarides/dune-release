type item = {
  id : string;
  year : int;
  month : int;
  week : int;
  user : string;
  days : Okra.Time.t;
}

type t = (string, item) Hashtbl.t

val of_markdown :
  ?acc:t ->
  path:string ->
  year:int ->
  week:int ->
  users:string list option ->
  ids:Filter.query list option ->
  lint:bool ->
  string ->
  (t, [ `Msg of string ]) result

val csv_headers : string list
val to_csv : t -> string

val of_csv :
  years:int list ->
  weeks:Weeks.t ->
  users:string list option ->
  ids:Filter.query list option ->
  string ->
  t
