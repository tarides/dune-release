module U = Yojson.Safe.Util

let ( / ) a b = U.member b a

type t = {
  id : string; (* unique field *)
  title : string;
  objective : string;
  status : string;
  schedule : string;
  other_fields : (string * string) list;
}

let v ~title ~objective ~status ?(schedule = "") ?(other_fields = []) id =
  { title; objective; status; schedule; other_fields; id }

let csv_headers = [ "Id"; "Objective"; "Title"; "Status"; "Schedule" ]
let to_csv t = [ t.id; t.objective; t.title; t.status; t.schedule ]
let other_fields t = t.other_fields
let id t = t.id

let get t = function
  | Column.Id -> t.id
  | Title -> t.title
  | Objective -> t.objective
  | Status -> t.status
  | Schedule -> t.status
  | Other_field f -> List.assoc f t.other_fields

let trace_assoc f a =
  match List.assoc_opt f a with
  | Some v -> v
  | None ->
      Fmt.failwith "assoc(%s): %a -> Not found\n" f
        Fmt.Dump.(list (pair string Yojson.Safe.pp))
        a

let first_assoc = function
  | [] -> failwith "empty assoc list"
  | (_, v) :: _ -> v

let graphql =
  {|
          fieldValues(first: 10) {
            nodes {
              ... on ProjectV2ItemFieldTextValue {
                text
                field {
                  ... on ProjectV2FieldCommon {
                    name
                  }
                }
              }
              ... on ProjectV2ItemFieldSingleSelectValue {
                name
                field {
                  ... on ProjectV2FieldCommon {
                    name
                  }
                }
              }
            }
          }
  |}

let parse json =
  let json = json / "fieldValues" / "nodes" |> U.to_list in
  List.fold_left
    (fun acc (json : Yojson.Safe.t) ->
      match json with
      | `Assoc [] -> acc
      | `Assoc a -> (
          let k = trace_assoc "field" a / "name" |> U.to_string in
          let v = first_assoc a |> U.to_string in
          match String.lowercase_ascii k with
          | "title" -> { acc with title = v }
          | "id" -> { acc with id = v }
          | "objective" -> { acc with objective = v }
          | "status" -> { acc with status = v }
          | "schedule" -> { acc with schedule = v }
          | _ -> { acc with other_fields = (k, v) :: acc.other_fields })
      | _ -> acc)
    {
      title = "";
      id = "";
      objective = "";
      status = "";
      schedule = "";
      other_fields = [];
    }
    json

let pp ppf t =
  Fmt.pf ppf "  [%7s] %a\n" t.id Fmt.(styled `Bold string) t.title;
  Fmt.pf ppf "    %a: %s\n"
    Fmt.(styled `Italic string)
    "Objective   " t.objective;
  Fmt.pf ppf "    %a: %s\n" Fmt.(styled `Italic string) "Status      " t.status;
  Fmt.pf ppf "    %a: %s\n"
    Fmt.(styled `Italic string)
    "Schedule    " t.schedule;
  List.iter (fun (k, v) -> Fmt.pf ppf "    %-12s: %s\n" k v) t.other_fields

let order_by (pivot : Column.t) cards =
  let sections = Hashtbl.create 12 in
  List.iter
    (fun card ->
      let name = get card pivot in
      let others =
        match Hashtbl.find_opt sections name with None -> [] | Some l -> l
      in
      Hashtbl.replace sections name (card :: others))
    cards;
  Hashtbl.fold (fun k v acc -> (k, v) :: acc) sections []

let matches f card =
  List.exists
    (fun (k, q) ->
      try
        let v = String.lowercase_ascii (get card k) in
        match q with
        | Filter.Is x -> x = v
        | Starts_with x -> String.starts_with ~prefix:x v
      with Not_found -> false)
    f

let filter_out f cards =
  List.fold_left
    (fun acc card ->
      let matching = matches f card in
      if matching then acc else card :: acc)
    [] cards
  |> List.rev
