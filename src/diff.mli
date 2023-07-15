type t

val pp : t Fmt.t
val apply : t -> unit Lwt.t

val v :
  ?db:Okra.Masterdb.t ->
  ?heatmap:Heatmap.t ->
  ?goals:(string, Issue.t) Hashtbl.t ->
  Card.t ->
  t

val concat : t list -> t
val lint : t -> unit
