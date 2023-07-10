module U = Yojson.Safe.Util

let ( / ) a b = U.member b a

type t = {
  org : string;
  number : int;
  title : string;
  cards : Card.t list;
  (* for mutations *)
  fields : Fields.t;
  uuid : string;
}

let org t = t.org
let number t = t.number

module Query = struct
  let fields =
    {|
      fields(first: 100) {
        nodes {
          ... on ProjectV2Field {
            name
            id
            dataType
          }
          ... on ProjectV2IterationField {
            name
            id
            dataType
          }
          ... on ProjectV2SingleSelectField {
            name
            id
            dataType
            options { id name }
          }
        }
      }
    |}

  let make ~org ~project_number ~after =
    Printf.sprintf
      {|
query {
  organization(login: %S) {
    projectV2(number: %d) {
      id
      title%s
      items(first: 100 %s) {
        edges {
          cursor
          node { %s
          }
        }
      }
    }
  }
}
|}
      org project_number
      (match after with None -> fields | Some _ -> "")
      (match after with
      | None -> ""
      | Some s -> Printf.sprintf ", after: \"%s\" " s)
      Card.graphql_query

  let parse_fields json =
    let json = json / "nodes" |> U.to_list in
    let fields = Fields.empty () in
    List.iter
      (fun json ->
        let key = json / "name" |> U.to_string |> Column.of_string in
        let id = json / "id" |> U.to_string in
        let kind = json / "dataType" |> U.to_string |> Fields.kind_of_string in
        match kind with
        | Text | Date -> Fields.add fields key kind id
        | Single_select _ ->
            let options = json / "options" |> U.to_list in
            let options =
              List.map
                (fun json ->
                  let id = json / "id" |> U.to_string in
                  let name = json / "name" |> U.to_string in
                  Fields.option ~name ~id)
                options
            in
            Fields.add fields key (Single_select options) id)
      json;
    fields

  let parse ?fields ~org ~project_number json =
    let json = json / "data" / "organization" / "projectV2" in
    let uuid = json / "id" |> U.to_string in
    let fields =
      match fields with None -> json / "fields" |> parse_fields | Some f -> f
    in
    let title = json / "title" |> U.to_string in
    let edges = json / "items" / "edges" |> U.to_list in
    match edges with
    | [] ->
        ("", { org; uuid; title; cards = []; fields; number = project_number })
    | edges ->
        let cursor = (List.rev edges |> List.hd) / "cursor" |> U.to_string in
        let cards =
          List.map
            (fun edge ->
              edge / "node"
              |> Card.parse_github_query ~project_uuid:uuid ~fields)
            edges
        in
        (cursor, { org; uuid; title; cards; fields; number = project_number })
end

let filter ?(filter_out = Filter.default_out) data =
  { data with cards = Card.filter_out filter_out data.cards }

let to_csv t =
  let headers = Card.csv_headers in
  let rows = List.map (fun card -> Card.to_csv card) t.cards in
  let buffer = Buffer.create 10 in
  let out = Csv.to_buffer ~quote_all:true buffer in
  Csv.output_all out (headers :: rows);
  Csv.close_out out;
  Buffer.contents buffer

let to_json t =
  let fields = Fields.to_json t.fields in
  let jsons = List.map Card.to_json t.cards in
  `Assoc
    [
      ("org", `String t.org);
      ("number", `Int t.number);
      ("title", `String t.title);
      ("cards", `List jsons);
      ("fields", fields);
      ("uuid", `String t.uuid);
    ]

let of_json json =
  let number = json / "number" |> U.to_int in
  let title = json / "title" |> U.to_string in
  let fields = json / "fields" |> Fields.of_json in
  let uuid = json / "uuid" |> U.to_string in
  let org = json / "org" |> U.to_string in
  let cards =
    json / "cards" |> U.to_list
    |> List.map (Card.of_json ~fields ~project_uuid:uuid)
  in
  { org; number; title; fields; cards; uuid }

let pp ?(order_by = Column.Objective) ?(filter_out = Filter.default_out) ppf t =
  Fmt.pf ppf "\n== %s (%d) ==\n" t.title t.number;
  let sections = Card.filter_out filter_out t.cards in
  let sections = Card.order_by order_by sections in
  if List.compare_length_with sections 1 = 0 then
    List.iter (Card.pp ppf) t.cards
  else
    List.iter
      (fun (name, section) ->
        Fmt.pf ppf "\n - %s -\n" name;
        List.iter (Card.pp ppf) section)
      sections

let diff ?heatmap ?db (t : t) =
  let diffs = List.map (Diff.v ?heatmap ?db) t.cards in
  let diffs = Diff.concat diffs in
  diffs

let sync ?heatmap ?db t = Diff.apply (diff ?heatmap ?db t)
let lint ?heatmap ~db t = Diff.lint (diff ?heatmap ~db t)

let get ~org ~project_number () =
  let open Lwt.Syntax in
  let rec aux fields cursor acc =
    let query = Query.make ~org ~project_number ~after:cursor in
    let* json = Github.run query in
    let cursor, project = Query.parse ?fields ~project_number ~org json in
    if List.length project.cards < 100 then
      Lwt.return { project with cards = acc @ project.cards }
    else aux (Some project.fields) (Some cursor) (acc @ project.cards)
  in
  aux None None []

let get_id_and_fields ~org ~project_number =
  let open Lwt.Syntax in
  let query = Query.make ~org ~project_number ~after:None in
  let+ json = Github.run query in
  let _, project = Query.parse ~project_number ~org json in
  (project.uuid, project.fields)

let get_all ~org project_numbers =
  Lwt_list.map_p
    (fun project_number -> get ~org ~project_number ())
    project_numbers
