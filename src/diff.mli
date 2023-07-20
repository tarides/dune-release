type t

val empty : t
val card_column : Card.t -> Column.t -> set:string -> old:string -> t
val card_state : Card.t -> set:[ `Closed | `Open ] -> t
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
