type t =
  | Title
  | Id
  | Objective
  | Status
  | Labels
  | Team
  | Pillar
  | Assignees
  | Quarter
  | Funder
  | Stakeholder
  | Size
  | Category
  | Starts
  | Ends
  | Tracks
  | Progress
  | Other_field of string

val all : t list
val to_string : t -> string
val of_string : string -> t
val pp : t Fmt.t
