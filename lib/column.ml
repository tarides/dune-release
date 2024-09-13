type t =
  | Title
  | Id
  | Objective
  | Status
  | Labels
  | Team
  | Pillar
  | Assignees
  | Iteration
  | Funder
  | Stakeholder
  | Size
  | Category
  | Starts
  | Ends
  | Tracks
  | Progress
  | Other_field of string

let all =
  [
    Title;
    Id;
    Objective;
    Status;
    Labels;
    Team;
    Pillar;
    Assignees;
    Iteration;
    Funder;
    Stakeholder;
    Size;
    Category;
    Tracks;
    Starts;
    Ends;
    Progress;
  ]

let to_string = function
  | Title -> "title"
  | Id -> "id"
  | Objective -> "objective"
  | Status -> "status"
  | Labels -> "labels"
  | Team -> "team"
  | Pillar -> "pillar"
  | Assignees -> "assignees"
  | Iteration -> "iteration"
  | Funder -> "funder"
  | Stakeholder -> "stakeholder"
  | Size -> "size"
  | Category -> "category"
  | Starts -> "starts"
  | Ends -> "ends"
  | Tracks -> "tracks"
  | Progress -> "progress"
  | Other_field f -> f

let pp = Fmt.of_to_string to_string

let of_string x =
  match String.lowercase_ascii x with
  | "title" -> Title
  | "id" -> Id
  | "objective" -> Objective
  | "status" -> Status
  | "labels" -> Labels
  | "team" -> Team
  | "pillar" -> Pillar
  | "assignees" -> Assignees
  | "iteration" -> Iteration
  | "funder" -> Funder
  | "stakeholder" -> Stakeholder
  | "size" -> Size
  | "category" -> Category
  | "tracks" -> Tracks
  | "start date" | "starts" -> Starts
  | "target date" | "ends" | "end date" -> Ends
  | "progress" -> Progress
  | f -> Other_field f
