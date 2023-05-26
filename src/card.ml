module U = Yojson.Safe.Util

let ( / ) a b = U.member b a

(** Fields *)

type t = {
  id : string; (* unique field - human readable ID used everywhere *)
  title : string;
  objective : string;
  status : string;
  schedule : string;
  funders : string list;
  team : string;
  starts : string;
  ends : string;
  other_fields : (string * string) list;
  (* for mutations *)
  fields : Fields.t;
  item_id : string;
  project_id : string;
}

let v ~title ~objective ?(status = "") ?(team = "") ?(funders = [])
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
    funders;
    id;
    fields = Fields.empty ();
    item_id = "";
    project_id = "";
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
    "Funders";
    "Team";
    "Starts";
    "Ends";
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
    String.concat "," t.funders;
    t.team;
  ]

let other_fields t = t.other_fields
let id t = t.id

let get t = function
  | Column.Id -> t.id
  | Title -> t.title
  | Objective -> t.objective
  | Status -> t.status
  | Schedule -> t.status
  | Starts -> t.starts
  | Ends -> t.ends
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

let parse ~project_id ~fields json =
  let item_id = json / "id" |> U.to_string in
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
          | Other_field "funder" -> { acc with funders = [ v ] }
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
      funders = [];
      team = "";
      other_fields = [];
      fields;
      item_id;
      project_id;
    }
    json

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
  pf_field "Funders" (String.concat ", " t.funders);
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

let is_complete t = matches [ (Objective, Filter.starts_with "complete") ] t
let is_dropped t = matches [ (Objective, Filter.starts_with "dropped") ] t

let filter_out f cards =
  List.fold_left
    (fun acc card ->
      let matching = matches f card in
      if matching then acc else card :: acc)
    [] cards
  |> List.rev

let graphql_mutate t field v =
  let field_kind, field_id =
    try Fields.find t.fields field
    with Not_found -> Fmt.failwith "XXX mutate %a\n" Fields.pp t.fields
  in
  let text =
    match field_kind with
    | Text -> Fmt.str "text: %S" v
    | Date -> Fmt.str "date: %S" v
    | Single_select -> Fmt.str "singleSelectOptionId: %S" v
  in
  Fmt.str
    {|
  mutation {
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
    t.project_id t.item_id field_id text

let sync ~heatmap t =
  let starts = Heatmap.start_date heatmap t.id in
  let ends = Heatmap.end_date heatmap t.id in
  let starts =
    let str = Fmt.to_to_string Heatmap.pp_start_date in
    match (starts, t.starts) with
    | None, "" -> None
    | Some x, "" ->
        let x = str x in
        Fmt.epr "%s has started in %s but is not recorded on the card\n" t.id x;
        Some x
    | Some x, y ->
        let x = str x in
        if x <> y then Fmt.epr "%s: start dates mismatch - %s vs. %s\n" t.id x y;
        Some x
    | None, x ->
        Fmt.epr "%s hasn't started by was planning to start on %s\n" t.id x;
        None
  in
  let ends =
    let str = Fmt.to_to_string Heatmap.pp_end_date in
    if is_complete t || is_dropped t then (
      match (ends, t.ends) with
      | None, "" -> None
      | Some x, "" ->
          let x = str x in
          Fmt.epr "%s has ended in %s but is not recorded on the card\n" t.id x;
          Some x
      | Some x, y ->
          let x = str x in
          if x <> y then Fmt.epr "%s: end dates mismatch - %s - %s\n" t.id x y;
          Some x
      | None, x ->
          Fmt.epr "%s hasn't started by was planning to end on %s\n" t.id x;
          None)
    else None
  in
  let () =
    match starts with
    | None -> ()
    | Some x ->
        let s = graphql_mutate t Starts x in
        Fmt.pr "UPDATE: %s\n" s
  in
  let () =
    match ends with
    | None -> ()
    | Some x ->
        let s = graphql_mutate t Ends x in
        Fmt.pr "UPDATE: %s\n" s
  in
  Lwt.return ()
