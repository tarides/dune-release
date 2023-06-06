type t = { id : string; title : string; cards : Card.t list }

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
          }
        }
      }
    |}

  let make ~org_name ~project_number ~after =
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
      org_name project_number
      (match after with None -> fields | Some _ -> "")
      (match after with
      | None -> ""
      | Some s -> Printf.sprintf ", after: \"%s\" " s)
      Card.graphql_query

  module U = Yojson.Safe.Util

  let ( / ) a b = U.member b a

  let parse_fields json =
    let json = json / "nodes" |> U.to_list in
    let fields = Fields.empty () in
    List.iter
      (fun json ->
        let key = json / "name" |> U.to_string |> Column.of_string in
        let id = json / "id" |> U.to_string in
        let kind = json / "dataType" |> U.to_string |> Fields.kind_of_string in
        Fields.add fields key kind id)
      json;
    fields

  let parse ?fields json =
    let json = json / "data" / "organization" / "projectV2" in
    let id = json / "id" |> U.to_string in
    let fields =
      match fields with None -> json / "fields" |> parse_fields | Some f -> f
    in
    let title = json / "title" |> U.to_string in
    let edges = json / "items" / "edges" |> U.to_list in
    match edges with
    | [] -> ("", fields, { id; title; cards = [] })
    | edges ->
        let cursor = (List.rev edges |> List.hd) / "cursor" |> U.to_string in
        let cards =
          List.map
            (fun edge -> edge / "node" |> Card.parse ~project_id:id ~fields)
            edges
        in
        (cursor, fields, { id; title; cards })
end

let filter ?(filter_out = Filter.default_out) data =
  { data with cards = Card.filter_out filter_out data.cards }

let to_csv t =
  let headers = "Project" :: Card.csv_headers in
  let rows = List.map (fun card -> t.title :: Card.to_csv card) t.cards in
  let buffer = Buffer.create 10 in
  let out = Csv.to_buffer ~quote_all:true buffer in
  Csv.output_all out (headers :: rows);
  Csv.close_out out;
  Buffer.contents buffer

let pp ?(order_by = Column.Objective) ?(filter_out = Filter.default_out) ppf t =
  Fmt.pf ppf "\n== %s (%s) ==\n" t.title t.id;
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

let sync ?heatmap ?db (t : t) =
  let diffs = List.map (Diff.v ?heatmap ?db) t.cards in
  let diffs = Diff.concat diffs in
  Diff.apply diffs

let lint ~db project = List.iter (Card.lint db) project.cards

let get ~org_name ~project_number () =
  let open Lwt.Syntax in
  let rec aux fields cursor acc =
    let query = Query.make ~org_name ~project_number ~after:cursor in
    let* json = Github.run query in
    let cursor, fields, project = Query.parse ?fields json in
    if List.length project.cards < 100 then
      Lwt.return { project with cards = acc @ project.cards }
    else aux (Some fields) (Some cursor) (acc @ project.cards)
  in
  aux None None []

let get_all ~org_name project_numbers =
  Lwt_list.map_p
    (fun project_number -> get ~org_name ~project_number ())
    project_numbers
