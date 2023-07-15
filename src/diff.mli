type t

val pp : t Fmt.t
val apply : t -> unit Lwt.t

val of_card :
  ?db:Okra.Masterdb.t ->
  ?heatmap:Heatmap.t ->
  ?goals:(string, Issue.t) Hashtbl.t ->
  Card.t ->
  t

val of_goal : Card.t list -> Issue.t -> t
val concat : t list -> t
val lint : t -> unit
