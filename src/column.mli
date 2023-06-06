type t =
  | Id
  | Title
  | Objective
  | Status
  | Schedule
  | Starts
  | Ends
  | Other_field of string

val to_string : t -> string
val of_string : string -> t
