type query = Is of string | Starts_with of string
type t = (Column.t * query) list

let is s = Is (String.lowercase_ascii s)
let starts_with s = Starts_with (String.lowercase_ascii s)

let default_out : t =
  [
    (Status, starts_with "complete");
    (Status, starts_with "dropped");
    (Id, is "");
    (Id, is "New KR");
  ]
