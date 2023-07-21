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
  pillar : string;
  stakeholder : string;
  category : string;
  starts : string;
  ends : string;
  other_fields : (string * string) list;
  (* for mutations *)
  project_id : string;
  card_id : string;
  issue_id : string; (* the issue the card points to *)
  issue_url : string;
  issue_closed : bool;
  tracked_by : string;
  fields : Fields.t;
}

let v ~title ~objective ?(status = "") ?(team = "") ?(funder = "")
    ?(pillar = "") ?(stakeholder = "") ?(category = "") ?(schedule = "")
    ?(starts = "") ?(ends = "") ?(project_id = "") ?(card_id = "")
    ?(issue_id = "") ?(issue_url = "") ?(issue_closed = false)
    ?(tracked_by = "") ?(other_fields = []) id =
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
    pillar;
    stakeholder;
    category;
    fields = Fields.empty ();
    project_id;
    card_id;
    issue_id;
    issue_url;
    issue_closed;
    tracked_by;
  }

let csv_headers =
  [
    "id";
    "title";
    "objective";
    "status";
    "schedule";
    "team";
    "category";
    "project";
    "funder";
  ]

let to_csv t =
  [
    t.id;
    t.title;
    t.objective;
    t.status;
    t.schedule;
    t.team;
    t.category;
    t.pillar;
    t.funder;
  ]

let json_fields =
  "issue_id" :: "issue_url" :: "issue_closed" :: "tracked-by"
  :: List.map String.lowercase_ascii csv_headers

let to_json t =
  `Assoc
    [
      ("id", `String t.id);
      ("title", `String t.title);
      ("objective", `String t.objective);
      ("status", `String t.status);
      ("schedule", `String t.schedule);
      ("funder", `String t.funder);
      ("team", `String t.team);
      ("pillar", `String t.pillar);
      ("stakeholder", `String t.stakeholder);
      ("category", `String t.category);
      ("starts", `String t.starts);
      ("ends", `String t.ends);
      ( "other-fields",
        `Assoc (List.map (fun (k, v) -> (k, `String v)) t.other_fields) );
      ("project-id", `String t.project_id);
      ("card-id", `String t.card_id);
      ("issue-id", `String t.issue_id);
      ("issue-url", `String t.issue_url);
      ("issue-closed", `Bool t.issue_closed);
      ("tracked-by", `String t.tracked_by);
    ]

let of_json ~project_id ~fields json =
  let id = json / "id" |> U.to_string in
  let objective = json / "objective" |> U.to_string in
  let title = json / "title" |> U.to_string in
  let status = json / "status" |> U.to_string in
  let schedule = json / "schedule" |> U.to_string in
  let starts = json / "starts" |> U.to_string in
  let ends = json / "ends" |> U.to_string in
  let funder = json / "funder" |> U.to_string in
  let team = json / "team" |> U.to_string in
  let pillar = json / "pillar" |> U.to_string in
  let stakeholder = json / "stakeholder" |> U.to_string in
  let category = json / "category" |> U.to_string in
  let card_id = json / "card-id" |> U.to_string in
  let issue_id = json / "issue-id" |> U.to_string in
  let issue_url = json / "issue-url" |> U.to_string in
  let issue_closed = json / "issue-closed" |> U.to_bool in
  let other_fields = json / "other-fields" |> U.to_assoc in
  let tracked_by = json / "tracked-by" |> U.to_string in
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
    other_fields = List.rev other_fields;
    card_id;
    project_id;
    fields;
    issue_id;
    issue_url;
    issue_closed;
    pillar;
    stakeholder;
    category;
    tracked_by;
  }

let other_fields t = t.other_fields
let id t = t.id
let tracked_by t = t.tracked_by
let issue_url t = t.issue_url
let issue_id t = t.issue_id
let issue_closed t = t.issue_closed
let team t = t.team
let pillar t = t.pillar
let stakeholder t = t.stakeholder
let category t = t.category
let card_id t = t.card_id
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
  | Team -> t.team
  | Pillar -> t.pillar
  | Stakeholder -> t.stakeholder
  | Category -> t.category
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
                url
                state
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
  | [] -> ("", "")
  | json :: _ ->
      let title = json / "title" |> U.to_string in
      let id = json / "id" |> U.to_string in
      (title, id)

let parse_github_query ~project_id ~fields json =
  let card_id = json / "id" |> U.to_string in
  let issue_id =
    try json / "content" / "id" |> U.to_string
    with _ ->
      Fmt.epr "XXX %a\n" Yojson.Safe.pp json;
      Fmt.epr "XXX missing ID for %s:" card_id;
      ""
  in
  let issue_url =
    try json / "content" / "url" |> U.to_string
    with _ ->
      Fmt.epr "XXX %a\n" Yojson.Safe.pp json;
      Fmt.epr "XXX missing url for %s:" card_id;
      ""
  in
  let issue_closed =
    try json / "content" / "state" |> U.to_string |> ( = ) "CLOSED"
    with _ ->
      Fmt.epr "XXX %a\n" Yojson.Safe.pp json;
      Fmt.epr "XXX missing state for %s:" card_id;
      false
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
            | Team -> { acc with team = v }
            | Pillar -> { acc with pillar = v }
            | Stakeholder -> { acc with stakeholder = v }
            | Category -> { acc with category = v }
            | Other_field k ->
                { acc with other_fields = (k, v) :: acc.other_fields })
        | _ -> acc)
      {
        title = "";
        id = "";
        objective = "";
        tracked_by = "";
        status = "";
        schedule = "";
        starts = "";
        ends = "";
        funder = "";
        team = "";
        pillar = "";
        stakeholder = "";
        category = "";
        other_fields = [];
        fields;
        card_id;
        issue_id;
        issue_url;
        issue_closed;
        project_id;
      }
      json
  in
  let objective, tracked_by =
    match json / "content" / "trackedInIssues" with
    | exception _ -> ("", "")
    | json -> json / "nodes" |> parse_objective
  in
  { t with objective; tracked_by }

let pp_state ppf = function
  | true -> Fmt.string ppf "closed"
  | false -> Fmt.string ppf "open"

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
  Fmt.pf ppf "  [%7s] %a (%a)\n" t.id bold t.title pp_state t.issue_closed;
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

let matches q t = Filter.eval ~get:(get t) q
let is_complete t = matches [ (Status, Filter.starts_with "complete") ] t
let is_dropped t = matches [ (Status, Filter.starts_with "dropped") ] t

let should_be_closed t =
  matches
    [
      (Status, Filter.starts_with "complete");
      (Status, Filter.starts_with "closed");
      (Status, Filter.starts_with "dropped");
    ]
    t

let should_be_open t = not (should_be_closed t)

let filter_out f cards =
  List.fold_left
    (fun acc card ->
      let matching = matches f card in
      if matching then acc else card :: acc)
    [] cards
  |> List.rev

module Raw = struct
  let graphql_update_inner ?name ~project_id ~card_id ~fields field v =
    let field_kind, field_id =
      try Fields.find fields field
      with Not_found ->
        Fmt.failwith "mutate: cannot find %a in %a\n" Column.pp field Fields.pp
          fields
    in
    let name = match name with None -> "" | Some n -> Fmt.str "%s: " n in
    match (v, field_kind) with
    | "", Single_select _ ->
        Fmt.str
          {|
    %sclearProjectV2ItemFieldValue(
      input: {
        projectId: %S
        itemId: %S
        fieldId: %S
      }
    ) {
      projectV2Item {
        id
      }
    }
  |}
          name project_id card_id field_id
    | _ ->
        let text =
          match field_kind with
          | Text -> Fmt.str "text: %S" v
          | Date -> Fmt.str "date: %S" v
          | Single_select options ->
              let id = Fields.get_id options ~name:v in
              Fmt.str "singleSelectOptionId: %S" id
        in
        Fmt.str
          {|
    %supdateProjectV2ItemFieldValue(
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
  |}
          name project_id card_id field_id text

  let graphql_update ~project_id ~card_id ~fields field v =
    Fmt.str
      {|
      mutation {
      %s
      }|}
      (graphql_update_inner ~project_id ~card_id ~fields field v)

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

  let update fields ~project_id ~card_id row =
    let open Lwt.Syntax in
    let mutations =
      List.mapi
        (fun i (k, v) ->
          let name = Fmt.str "update%d" i in
          graphql_update_inner ~name ~fields ~project_id ~card_id k v)
        row
      |> String.concat "\n"
      |> Fmt.str {| mutation { %s } |}
    in
    let+ _ = Github.run mutations in
    card_id

  let add fields ~project_id ~issue_id row =
    let open Lwt.Syntax in
    let* json = Github.run (graphql_add ~project_id ~issue_id) in
    let card_id = parse_card_id json in
    update fields ~project_id ~card_id row
end

let graphql_mutate { project_id; card_id; fields; _ } =
  Raw.graphql_update ~project_id ~card_id ~fields
