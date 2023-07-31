type query = Is of string | Not of query | Starts_with of string
type t = (Column.t * query) list

let is s = Is (String.lowercase_ascii s)
let starts_with s = Starts_with (String.lowercase_ascii s)

let default_out : t =
  [ (Status, starts_with "complete"); (Status, starts_with "dropped") ]

let rec eval_one ~get k q =
  let v = String.lowercase_ascii (get k) in
  match q with
  | Is x -> x = v
  | Not x -> not (eval_one ~get k x)
  | Starts_with x -> String.starts_with ~prefix:x v

let eval ~get t =
  List.exists (fun (k, q) -> try eval_one ~get k q with Not_found -> false) t

let query id =
  let check_is id =
    if String.ends_with ~suffix:"*" id then
      starts_with (String.sub id 0 (String.length id - 1))
    else is id
  in
  if String.starts_with ~prefix:"-" id then
    Not (check_is (String.sub id 1 (String.length id - 1)))
  else check_is id

let not t = Not t
