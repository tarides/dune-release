type t = Id | Title | Objective | Status | Schedule | Other_field of string

let to_string = function
  | Id -> "id"
  | Title -> "title"
  | Objective -> "objective"
  | Status -> "status"
  | Schedule -> "schedule"
  | Other_field f -> f
