module Query = struct
  type t = Is of string | Not of t | Starts_with of string

  let is s = Is (String.lowercase_ascii s)
  let starts_with s = Starts_with (String.lowercase_ascii s)
  let not t = Not t

  let rec pp ppf = function
    | Is s -> Fmt.pf ppf "Is %S" s
    | Not q -> Fmt.pf ppf "Not (%a)" pp q
    | Starts_with s -> Fmt.pf ppf "Starts_with %S" s

  let rec eval ~get k q =
    let v = String.lowercase_ascii (get k) in
    let lv = String.split_on_char ',' v in
    match q with
    | Is x -> List.exists (String.equal x) lv
    | Not x -> Stdlib.not (eval ~get k x)
    | Starts_with prefix -> List.exists (String.starts_with ~prefix) lv

  let make id =
    let check_is id =
      if String.ends_with ~suffix:"*" id then
        starts_with (String.sub id 0 (String.length id - 1))
      else is id
    in
    if String.starts_with ~prefix:"~" id then
      Not (check_is (String.sub id 1 (String.length id - 1)))
    else check_is id
end

type t = (Column.t * Query.t) list

let default_out : t =
  [
    (Status, Query.starts_with "complete");
    (Status, Query.starts_with "dropped");
    (Labels, Query.is "legacy");
  ]

let eval ~get t =
  List.exists
    (fun (k, q) -> try Query.eval ~get k q with Not_found -> false)
    t
