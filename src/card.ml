module U = Yojson.Safe.Util

let ( / ) a b = U.member b a

(** Fields *)

type t = {
  id : string; (* unique field - human readable ID used everywhere *)
  title : string;
  objective : string;
  status : string;
  schedule : string;
  funder : string;
  team : string;
  starts : string;
  ends : string;
  other_fields : (string * string) list;
  (* for mutations *)
  project_uuid : string;
  uuid : string;
  issue_uuid : string; (* the issue the card points to *)
  fields : Fields.t;
}

let v ~title ~objective ?(status = "") ?(team = "") ?(funder = "")
    ?(schedule = "") ?(starts = "") ?(ends = "") ?(other_fields = []) id =
  {
    title;
    objective;
    status;
    schedule;
    starts;
    ends;
    other_fields;
    team;
    funder;
    id;
    fields = Fields.empty ();
    project_uuid = "";
    uuid = "";
    issue_uuid = "";
  }

let csv_headers =
  [
    "Id";
    "Objective";
    "Title";
    "Status";
    "Schedule";
    "Starts";
    "Ends";
    "Funder";
    "Team";
  ]

let to_csv t =
  [
    t.id;
    t.objective;
    t.title;
    t.status;
    t.schedule;
    t.starts;
    t.ends;
    t.funder;
    t.team;
  ]

let json_fields = "uuid" :: List.map String.lowercase_ascii csv_headers

let to_json t =
  `Assoc
    [
      ("id", `String t.id);
      ("objective", `String t.objective);
      ("title", `String t.title);
      ("status", `String t.status);
      ("schedule", `String t.schedule);
      ("starts", `String t.starts);
      ("ends", `String t.ends);
      ("funder", `String t.funder);
      ("team", `String t.team);
      ("uuid", `String t.uuid);
      ("issue_uuid", `String t.issue_uuid);
    ]

let of_json ~project_uuid ~fields json =
  let id = json / "id" |> U.to_string in
  let issue_uuid = json / "issue_id" |> U.to_string in
  let objective = json / "objective" |> U.to_string in
  let title = json / "title" |> U.to_string in
  let status = json / "status" |> U.to_string in
  let schedule = json / "schedule" |> U.to_string in
  let starts = json / "starts" |> U.to_string in
  let ends = json / "ends" |> U.to_string in
  let funder = json / "funder" |> U.to_string in
  let team = json / "team" |> U.to_string in
  let uuid = json / "uuid" |> U.to_string in
  let other_fields = json |> U.to_assoc in
  let other_fields =
    List.fold_left
      (fun acc (x, y) ->
        if List.mem x json_fields then acc else (x, U.to_string y) :: acc)
      [] other_fields
  in
  {
    id;
    objective;
    title;
    status;
    schedule;
    starts;
    ends;
    funder;
    team;
    other_fields;
    uuid;
    project_uuid;
    fields;
    issue_uuid;
  }

let other_fields t = t.other_fields
let id t = t.id
let ends t = t.ends
let starts t = t.starts
let objective t = t.objective
let title t = t.title
let status t = t.status
let funder t = t.funder
let schedule t = t.schedule

let get t = function
  | Column.Id -> t.id
  | Title -> t.title
  | Objective -> t.objective
  | Status -> t.status
  | Schedule -> t.status
  | Starts -> t.starts
  | Ends -> t.ends
  | Funder -> t.funder
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

let graphql_query =
  {|
            id
            content {
              ... on Issue {
                id
                trackedInIssues(first:10) {
                  nodes {
                    id
                    title
                  }
                }
              }
            }
            fieldValues(first: 100) {
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
                ... on ProjectV2ItemFieldDateValue {
                  date
                  field {
                    ... on ProjectV2FieldCommon {
                      name
                    }
                  }
                }
              }
            }
  |}

(* FIXME: not super generic *)
let parse_objective json =
  match U.to_list json with
  | [] -> ""
  | json :: _ ->
      let _id = json / "id" |> U.to_string in
      let title = json / "title" |> U.to_string in
      title

let parse_github_query ~project_uuid ~fields json =
  let uuid = json / "id" |> U.to_string in
  let issue_uuid =
    try json / "content" / "id" |> U.to_string
    with _ ->
      Fmt.epr "XXX %a\n" Yojson.Safe.pp json;
      Fmt.epr "XXX missing ID for %s:" uuid;
      ""
  in
  let t =
    let json = json / "fieldValues" / "nodes" |> U.to_list in
    List.fold_left
      (fun acc (json : Yojson.Safe.t) ->
        match json with
        | `Assoc [] -> acc
        | `Assoc a -> (
            let k = trace_assoc "field" a / "name" |> U.to_string in
            let v = first_assoc a |> U.to_string in
            let c = Column.of_string k in
            match c with
            | Title -> { acc with title = v }
            | Id -> { acc with id = v }
            | Objective -> { acc with objective = v }
            | Status -> { acc with status = v }
            | Schedule -> { acc with schedule = v }
            | Starts -> { acc with starts = v }
            | Ends -> { acc with ends = v }
            | Funder -> { acc with funder = v }
            | Other_field "team" -> { acc with team = v }
            | Other_field k ->
                { acc with other_fields = (k, v) :: acc.other_fields })
        | _ -> acc)
      {
        title = "";
        id = "";
        objective = "";
        status = "";
        schedule = "";
        starts = "";
        ends = "";
        funder = "";
        team = "";
        other_fields = [];
        fields;
        uuid;
        issue_uuid;
        project_uuid;
      }
      json
  in
  let objective =
    match json / "content" / "trackedInIssues" with
    | exception _ -> ""
    | json -> json / "nodes" |> parse_objective
  in
  { t with objective }

let pp ppf t =
  let em = Fmt.(styled `Italic string) in
  let bold = Fmt.(styled `Bold string) in
  let pf_field k v =
    let n = max 10 (String.length k) in
    let buf = Bytes.make n ' ' in
    String.blit k 0 buf 0 (String.length k);
    let k = String.of_bytes buf in
    match v with "" -> () | _ -> Fmt.pf ppf "    %a: %s\n" em k v
  in
  Fmt.pf ppf "  [%7s] %a\n" t.id bold t.title;
  pf_field "Objective" t.objective;
  pf_field "Status" t.status;
  pf_field "Schedule" t.schedule;
  pf_field "Starts" t.starts;
  pf_field "Ends" t.ends;
  pf_field "Team" t.team;
  pf_field "Funder" t.funder;
  List.iter (fun (k, v) -> pf_field (k ^ "*") v) t.other_fields

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

let is_complete t = matches [ (Status, Filter.starts_with "complete") ] t
let is_dropped t = matches [ (Status, Filter.starts_with "dropped") ] t

let filter_out f cards =
  List.fold_left
    (fun acc card ->
      let matching = matches f card in
      if matching then acc else card :: acc)
    [] cards
  |> List.rev

module Raw = struct
  let graphql_update ?name ~project_id ~card_id ~fields field v =
    let field_kind, field_id =
      try Fields.find fields field
      with Not_found ->
        Fmt.failwith "mutate: cannot find %a in %a\n" Column.pp field Fields.pp
          fields
    in
    let text =
      match field_kind with
      | Text -> Fmt.str "text: %S" v
      | Date -> Fmt.str "date: %S" v
      | Single_select options ->
          let id = Fields.get_id options ~name:v in
          Fmt.str "singleSelectOptionId: %S" id
    in
    let id = match name with None -> "" | Some id -> id ^ " " in
    Fmt.str
      {|
  mutation %s{
    updateProjectV2ItemFieldValue(
      input: {
        projectId: %S
        itemId: %S
        fieldId: %S
        value: { %s }
      }
    ) {
      projectV2Item {
        id
      }
    }
  }
  |}
      id project_id card_id field_id text

  let graphql_add ~project_id ~issue_id =
    Fmt.str
      {|
      mutation {
        addProjectV2ItemById(input: {projectId: %S contentId: %S}) {
          item {
            id
          }
        }
      }
  |}
      project_id issue_id

  let parse_card_id json =
    U.(
      json |> member "data"
      |> member "addProjectV2ItemById"
      |> member "item" |> member "id" |> to_string)

  let add fields ~project_id ~issue_id row =
    let open Lwt.Syntax in
    let* json = Github.run (graphql_add ~project_id ~issue_id) in
    let card_id = parse_card_id json in
    let mutations =
      List.mapi
        (fun i (k, v) ->
          let name = Fmt.str "M%d" i in
          graphql_update ~name ~fields ~project_id ~card_id k v)
        row
      |> String.concat "\n"
    in
    let+ _ = Github.run mutations in
    card_id

  let update fields ~project_id ~card_id row =
    let open Lwt.Syntax in
    let mutations =
      List.map
        (fun (k, v) -> graphql_update ~fields ~project_id ~card_id k v)
        row
      |> String.concat "\n"
    in
    let+ _ = Github.run mutations in
    card_id
end

let graphql_mutate ?name t =
  Raw.graphql_update ?name ~project_id:t.project_uuid ~card_id:t.uuid
    ~fields:t.fields
