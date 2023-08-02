module U = Yojson.Safe.Util

let ( / ) a b =
  try U.member b a
  with Yojson.Safe.Util.Type_error _ as e ->
    Fmt.epr "Cannot find field %S in %a\n%!" b Yojson.Safe.pp a;
    raise e

type t = {
  title : string;
  id : string;
  objective : string;
  status : string;
  labels : string list;
  team : string;
  pillar : string;
  assignees : string list;
  quarter : string;
  funder : string;
  stakeholder : string;
  size : string;
  tracks : string list;
  category : string;
  starts : string;
  ends : string;
  other_fields : (string * string) list;
  (* for mutations *)
  project_id : string;
  card_id : string;
  issue_id : string; (* the issue the card points to *)
  issue_url : string;
  state : [ `Open | `Closed | `Draft ];
  tracked_by : string; (* the ID of the [objective] field *)
  fields : Fields.t;
}

let v ?(title = "") ?(objective = "") ?(status = "") ?(labels = []) ?(team = "")
    ?(pillar = "") ?(assignees = []) ?(quarter = "") ?(funder = "")
    ?(stakeholder = "") ?(size = "") ?(tracks = []) ?(category = "")
    ?(other_fields = []) ?(starts = "") ?(ends = "") ?(project_id = "")
    ?(card_id = "") ?(issue_id = "") ?(issue_url = "") ?(state = `Open)
    ?(tracked_by = "") id =
  {
    title;
    id;
    objective;
    status;
    labels;
    team;
    pillar;
    assignees;
    quarter;
    funder;
    stakeholder;
    size;
    tracks;
    category;
    starts;
    ends;
    other_fields;
    fields = Fields.empty ();
    project_id;
    card_id;
    issue_id;
    issue_url;
    state;
    tracked_by;
  }

let empty = v ""

let csv_headers =
  [
    "id"; "title"; "status"; "quarter"; "team"; "pillar"; "objective"; "funder";
  ]

let to_csv t =
  [
    t.id; t.title; t.status; t.quarter; t.team; t.pillar; t.objective; t.funder;
  ]

let get ~one ~many t = function
  | Column.Id -> one t.id
  | Title -> one t.title
  | Objective -> one t.objective
  | Status -> one t.status
  | Quarter -> one t.quarter
  | Starts -> one t.starts
  | Ends -> one t.ends
  | Funder -> one t.funder
  | Team -> one t.team
  | Pillar -> one t.pillar
  | Stakeholder -> one t.stakeholder
  | Category -> one t.category
  | Labels -> many t.labels
  | Assignees -> many t.assignees
  | Size -> one t.size
  | Tracks -> many t.tracks
  | Other_field f -> one (List.assoc f t.other_fields)

let get_string = get ~one:(fun s -> s) ~many:(fun s -> String.concat "," s)

let get_json =
  let one s = `String s in
  get ~one ~many:(fun s -> `List (List.map one s))

let json_fields =
  "issue_id" :: "issue_url" :: "issue_closed" :: "tracked-by"
  :: List.map String.lowercase_ascii csv_headers

let state_of_string = function
  | "open" -> `Open
  | "closed" -> `Closed
  | "draft" -> `Draft
  | s -> Fmt.failwith "invalid state: %s" s

let string_of_state = function
  | `Open -> "open"
  | `Closed -> "closed"
  | `Draft -> "draft"

let to_json t =
  let columns =
    List.map (fun c -> (Column.to_string c, get_json t c)) Column.all
  in
  let other_fields =
    `Assoc (List.map (fun (k, v) -> (k, `String v)) t.other_fields)
  in
  `Assoc
    (columns
    @ [
        ("other-fields", other_fields);
        ("project-id", `String t.project_id);
        ("card-id", `String t.card_id);
        ("issue-id", `String t.issue_id);
        ("issue-url", `String t.issue_url);
        ("state", `String (string_of_state t.state));
        ("tracked-by", `String t.tracked_by);
      ])

let of_json ~project_id ~fields json =
  let id = json / "id" |> U.to_string in
  let objective = json / "objective" |> U.to_string in
  let title = json / "title" |> U.to_string in
  let status = json / "status" |> U.to_string in
  let tracks = json / "tracks" |> U.to_list |> List.map U.to_string in
  let starts = json / "starts" |> U.to_string in
  let ends = json / "ends" |> U.to_string in
  let funder = json / "funder" |> U.to_string in
  let stakeholder = json / "stakeholder" |> U.to_string in
  let team = json / "team" |> U.to_string in
  let size = json / "size" |> U.to_string in
  let pillar = json / "pillar" |> U.to_string in
  let quarter = json / "quarter" |> U.to_string in
  let category = json / "category" |> U.to_string in
  let assignees = json / "assignees" |> U.to_list |> List.map U.to_string in
  let labels = json / "labels" |> U.to_list |> List.map U.to_string in
  let card_id = json / "card-id" |> U.to_string in
  let issue_id = json / "issue-id" |> U.to_string in
  let issue_url = json / "issue-url" |> U.to_string in
  let state = json / "state" |> U.to_string |> state_of_string in
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
    quarter;
    starts;
    tracks;
    ends;
    funder;
    team;
    size;
    assignees;
    labels;
    other_fields = List.rev other_fields;
    card_id;
    project_id;
    fields;
    issue_id;
    issue_url;
    state;
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
let state t = t.state
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
let quarter t = t.quarter
let tracks t = t.tracks

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
               ... on DraftIssue {
                 id
              }
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

let id_of_url s =
  match List.rev (String.split_on_char '/' s) with
  | id :: _ -> "#" ^ id
  | _ -> assert false

let parse_github_query ~project_id ~fields json =
  let card_id = json / "id" |> U.to_string in
  let state =
    match json / "content" / "state" |> U.to_string with
    | "CLOSED" -> `Closed
    | "OPEN" -> `Open
    | s -> Fmt.failwith "invalid state received from the Github API: %S" s
    | exception Yojson.Safe.Util.Type_error _ -> `Draft
  in
  let issue_id = json / "content" / "id" |> U.to_string in
  let issue_url =
    match state with
    | `Draft -> ""
    | `Open | `Closed -> json / "content" / "url" |> U.to_string
  in
  let t =
    let json = json / "fieldValues" / "nodes" |> U.to_list in
    List.fold_left
      (fun acc (json : Yojson.Safe.t) ->
        match json with
        | `Assoc [] -> acc
        | `Assoc a -> (
            let k = trace_assoc "field" a / "name" |> U.to_string in
            let one a = first_assoc a |> U.to_string in
            let many a = first_assoc a |> U.to_list |> List.map U.to_string in
            let c = Column.of_string k in
            match c with
            | Title -> { acc with title = one a }
            | Id -> { acc with id = one a }
            | Objective -> { acc with objective = one a }
            | Status -> { acc with status = one a }
            | Quarter -> { acc with quarter = one a }
            | Labels -> { acc with labels = many a }
            | Starts -> { acc with starts = one a }
            | Size -> { acc with size = one a }
            | Assignees -> { acc with assignees = many a }
            | Ends -> { acc with ends = one a }
            | Funder -> { acc with funder = one a }
            | Team -> { acc with team = one a }
            | Pillar -> { acc with pillar = one a }
            | Tracks -> { acc with tracks = many a }
            | Stakeholder -> { acc with stakeholder = one a }
            | Category -> { acc with category = one a }
            | Other_field k ->
                { acc with other_fields = (k, one a) :: acc.other_fields })
        | _ -> acc)
      { empty with fields; card_id; issue_id; issue_url; state; project_id }
      json
  in
  let objective, tracked_by =
    match state with
    | `Draft -> ("", "")
    | `Open | `Closed -> (
        match json / "content" / "trackedInIssues" with
        | exception _ -> ("", "")
        | json -> json / "nodes" |> parse_objective)
  in
  let id = match t.id with "" -> id_of_url t.issue_url | s -> s in
  { t with objective; tracked_by; id }

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
  Fmt.pf ppf "  [%7s] %a (%s)\n" t.id bold t.title (string_of_state t.state);
  pf_field "Objective" t.objective;
  pf_field "Status" t.status;
  pf_field "Quarter" t.quarter;
  pf_field "Starts" t.starts;
  pf_field "Ends" t.ends;
  pf_field "Team" t.team;
  pf_field "Funder" t.funder;
  List.iter (fun (k, v) -> pf_field (k ^ "*") v) t.other_fields

let order_by (pivot : Column.t) cards =
  let sections = Hashtbl.create 12 in
  List.iter
    (fun card ->
      let name = get_string card pivot in
      let others =
        match Hashtbl.find_opt sections name with None -> [] | Some l -> l
      in
      Hashtbl.replace sections name (card :: others))
    cards;
  Hashtbl.fold (fun k v acc -> (k, v) :: acc) sections []

let matches q t = Filter.eval ~get:(get_string t) q
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
