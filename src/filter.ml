type query = Is of string | Is_not of string | Starts_with of string
type t = (Column.t * query) list

let is s = Is (String.lowercase_ascii s)
let is_not s = Is_not (String.lowercase_ascii s)
let starts_with s = Starts_with (String.lowercase_ascii s)

let default_out : t =
  [
    (Status, starts_with "complete");
    (Status, starts_with "dropped");
    (Id, is "");
    (Id, is "New KR");
  ]

let eval_one ~get k q =
  let v = String.lowercase_ascii (get k) in
  match q with
  | Is x -> x = v
  | Is_not x -> x <> v
  | Starts_with x -> String.starts_with ~prefix:x v

let eval ~get t =
  List.exists (fun (k, q) -> try eval_one ~get k q with Not_found -> false) t
