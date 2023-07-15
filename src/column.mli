type t =
  | Id
  | Title
  | Objective
  | Status
  | Schedule
  | Starts
  | Ends
  | Funder
  | Team
  | Pillar
  | Stakeholder
  | Category
  | Other_field of string

val to_string : t -> string
val of_string : string -> t
val pp : t Fmt.t
