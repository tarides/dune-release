type t = (Column.t * string) list

let default_out =
  [ (Column.Status, "Complete ✅"); (Status, "Dropped ❌"); (Id, "") ]
