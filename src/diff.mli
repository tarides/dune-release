type t

val empty : t
val card_column : Card.t -> Column.t -> set:string -> old:string -> t
val card_state : Card.t -> set:[ `Closed | `Open ] -> t
val pp : t Fmt.t
val apply : t -> unit Lwt.t
val of_card : ?heatmap:Heatmap.t -> Card.t -> t
val of_goal : Card.t list -> Issue.t -> t
val concat : t list -> t
val lint : t -> unit
