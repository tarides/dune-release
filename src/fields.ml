module U = Yojson.Safe.Util

let ( / ) a b = U.member b a

type option = { id : string; name : string }
type kind = Text | Date | Single_select of option list
type t = (Column.t, kind * string) Hashtbl.t

let option ~id ~name = { id; name }
let pp_option ppf { id; name } = Fmt.pf ppf "%s:%s" id name
let pp_options = Fmt.Dump.(list pp_option)

let pp_kind ppf = function
  | Text -> Fmt.string ppf "Text"
  | Date -> Fmt.string ppf "Date"
  | Single_select l -> Fmt.pf ppf "Single_select %a" pp_options l

let pp ppf t =
  let l = Hashtbl.fold (fun k v acc -> (k, v) :: acc) t [] in
  Fmt.Dump.(list (pair Column.pp (pair pp_kind string))) ppf l

let get_id ~name l =
  match List.find (fun x -> String.starts_with ~prefix:name x.name) l with
  | x -> x.id
  | exception Not_found ->
      Fmt.epr "Cannot find name %s in %a\n" name pp_options l;
      failwith "boo"

let string_of_kind = function
  | Text -> "Text"
  | Single_select _ -> "SingleSelect"
  | Date -> "Date"

let kind_of_string = function
  | "ProjectV2ItemFieldDateValue" -> Date
  | "ProjectV2ItemFieldTextValue" -> Text
  | "ProjectV2ItemFieldSingleSelectValue" -> Single_select []
  | "DATE" -> Date
  | "TITLE" -> Text
  | "ASSIGNEES" -> Text
  | "LABELS" -> Text
  | "SINGLE_SELECT" -> Single_select []
  | "LINKED_PULL_REQUESTS" -> Text
  | "REPOSITORY" -> Text
  | "REVIEWERS" -> Text
  | "MILESTONE" -> Text
  | "TEXT" -> Text
  | "NUMBER" -> Text
  | "TRACKS" -> Text
  | "TRACKED_BY" -> Text
  | s -> Fmt.failwith "%s: invalid field kind" s

let find t k = Hashtbl.find t k
let empty () = Hashtbl.create 13
let add t c k s = Hashtbl.add t c (k, s)

let to_json t =
  let option { id; name } =
    `Assoc [ ("id", `String id); ("name", `String name) ]
  in
  let kind = function
    | Text -> `String "Text"
    | Date -> `String "Date"
    | Single_select l ->
        let l = List.map option l in
        `Assoc [ ("SingleSelect", `List l) ]
  in
  let column c = `String (Column.to_string c) in
  let field c k v =
    `Assoc [ ("column", column c); ("kind", kind k); ("value", `String v) ]
  in
  let all = Hashtbl.fold (fun c (k, v) acc -> field c k v :: acc) t [] in
  `List all

let option_of_json json =
  let id = json / "id" |> U.to_string in
  let name = json / "name" |> U.to_string in
  { id; name }

let kind_of_json = function
  | `String "Text" -> Text
  | `String "Date" -> Date
  | `Assoc [ ("SingleSelect", `List l) ] ->
      let l = List.map option_of_json l in
      Single_select l
  | json -> Fmt.failwith "invalid kind: %a\n" Yojson.Safe.pp json

let of_json json =
  let t = empty () in
  List.iter
    (fun json ->
      let c = json / "column" |> U.to_string |> Column.of_string in
      let k = json / "kind" |> kind_of_json in
      let s = json / "value" |> U.to_string in
      add t c k s)
    (U.to_list json);
  t
