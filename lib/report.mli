type item = {
  id : string;
  year : int;
  month : int;
  week : int;
  days : Okra.Time.t;
  hours : Okra.Time.t;
  user : string;
  funder : string;
  team : string;
  category : string;
  objective : string;
}

type t = (string, item) Hashtbl.t

val of_markdown :
  ?cards:Card.t list ->
  ?acc:t ->
  path:string ->
  year:int ->
  week:int ->
  users:string list option ->
  ids:Filter.Query.t list option ->
  lint:bool ->
  in_channel ->
  (t, [ `Msg of string ]) result

val to_csv : out_channel -> t -> unit

val of_csv :
  years:int list ->
  weeks:Weeks.t ->
  users:string list option ->
  ids:Filter.Query.t list option ->
  in_channel ->
  t
