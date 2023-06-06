type t =
  | Id
  | Title
  | Objective
  | Status
  | Schedule
  | Starts
  | Ends
  | Other_field of string

let to_string = function
  | Id -> "id"
  | Title -> "title"
  | Objective -> "objective"
  | Status -> "status"
  | Schedule -> "schedule"
  | Starts -> "starts"
  | Ends -> "ends"
  | Other_field f -> f

let pp = Fmt.of_to_string to_string

let of_string x =
  match String.lowercase_ascii x with
  | "id" -> Id
  | "title" -> Title
  | "objective" -> Objective
  | "status" -> Status
  | "schedule" -> Schedule
  | "start date" | "starts" -> Starts
  | "target date" | "ends" | "end date" -> Ends
  | f -> Other_field f
