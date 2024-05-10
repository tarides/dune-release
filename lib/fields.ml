module U = Yojson.Safe.Util

let ( / ) a b = U.member b a

type option = { id : string; name : string }

type kind =
  | Users
  | Pull_requests
  | Reviewers
  | Labels
  | Milestones
  | Repository
  | Title
  | Text
  | Single_select of option list
  | Number
  | Date
  | Iteration
  | Tracks
  | Tracked_by

type t = (Column.t, kind * string) Hashtbl.t

let option ~id ~name = { id; name }
let pp_option ppf { id; name } = Fmt.pf ppf "%s:%s" id name
let pp_options = Fmt.Dump.(list pp_option)

let pp_kind ppf = function
  | Users -> Fmt.string ppf "users"
  | Pull_requests -> Fmt.string ppf "pull-requests"
  | Reviewers -> Fmt.string ppf "reviewers"
  | Labels -> Fmt.string ppf "labels"
  | Milestones -> Fmt.string ppf "milestones"
  | Repository -> Fmt.string ppf "repository"
  | Title -> Fmt.string ppf "title"
  | Text -> Fmt.string ppf "text"
  | Single_select l -> Fmt.pf ppf "single-select@ %a" pp_options l
  | Number -> Fmt.string ppf "number"
  | Date -> Fmt.string ppf "date"
  | Iteration -> Fmt.string ppf "iteration"
  | Tracks -> Fmt.string ppf "tracks"
  | Tracked_by -> Fmt.string ppf "tracked_by"

let pp ppf t =
  let l = Hashtbl.fold (fun k v acc -> (k, v) :: acc) t [] in
  Fmt.Dump.(list (pair Column.pp (pair pp_kind string))) ppf l

let drop_color s =
  match String.split_on_char ':' s with
  | [] -> s
  | [ s ] -> s
  | [ _; s ] -> s
  | _ :: t -> String.concat ":" t

let same x y =
  let x = String.lowercase_ascii x in
  let y = String.lowercase_ascii y in
  (* drop colors *)
  let x = drop_color x in
  let y = drop_color y in
  String.starts_with ~prefix:x y || String.ends_with ~suffix:x y

let get_id ~name l =
  let name = String.lowercase_ascii name in
  match List.find (fun x -> same name x.name) l with
  | x -> x.id
  | exception Not_found ->
      Fmt.epr "Cannot find name %s in %a\n" name pp_options l;
      failwith "boo"

let kind_of_string s =
  match String.lowercase_ascii s with
  | "projectv2itemfielddatevalue" | "date" -> Date
  | "title" -> Title
  | "projectv2itemfielduservalue" | "assignees" | "users" -> Users
  | "projectv2itemfieldlabelvalue" | "labels" -> Labels
  | "projectv2itemfieldsingleselectvalue" | "single_select" | "single-select" ->
      Single_select []
  | "projectv2itemfieldpullrequestvalue" | "linked_pull_requests"
  | "pull-requests" ->
      Pull_requests
  | "projectv2itemfieldrepositoryvalue" | "repository" -> Repository
  | "projectv2itemfieldreviewervalue" | "reviewers" -> Reviewers
  | "projectv2itemfieldmilestonevalue" | "milestone" | "milestones" ->
      Milestones
  | "projectv2itemfieldtextvalue" | "text" -> Text
  | "projectv2itemfieldnumbervalue" | "number" -> Number
  | "tracks" -> Tracks
  | "tracked_by" | "tracked-by" -> Tracked_by
  | s -> Fmt.failwith "%s: invalid field kind" s

let find t k = Hashtbl.find t k
let empty () = Hashtbl.create 13
let add t c k s = Hashtbl.add t c (k, s)

let to_json t =
  let option { id; name } =
    `Assoc [ ("id", `String id); ("name", `String name) ]
  in
  let kind = function
    | Single_select l ->
        let l = List.map option l in
        `Assoc [ ("single-select", `List l) ]
    | k -> `String (Fmt.to_to_string pp_kind k)
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
  | `String s -> kind_of_string s
  | `Assoc [ ("single-select", `List l) ] ->
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
