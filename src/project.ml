type t = { id : string; title : string; cards : Card.t list }

module Query = struct
  let make ~org_name ~project_number ~after =
    Printf.sprintf
      {|
query { 
  organization(login: %S) {
    projectV2(number: %d) {
      id
      title
      items(first: 100 %s) {
        edges {
          cursor
          node {
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
          }
        }
      }
    }
  }
}
|}
      org_name project_number
      (match after with
      | None -> ""
      | Some s -> Printf.sprintf ", after: \"%s\" " s)

  module U = Yojson.Safe.Util

  let ( / ) a b = U.member b a

  let parse json =
    let json = json / "data" / "organization" / "projectV2" in
    let id = json / "id" |> U.to_string in
    let title = json / "title" |> U.to_string in
    let edges = json / "items" / "edges" |> U.to_list in
    match edges with
    | [] -> ("", { id; title; cards = [] })
    | edges ->
        let cursor = (List.rev edges |> List.hd) / "cursor" |> U.to_string in
        let cards = List.map (fun edge -> edge / "node" |> Card.parse) edges in
        (cursor, { id; title; cards })
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

let get ~org_name ~project_number =
  let open Lwt.Syntax in
  let rec aux cursor acc =
    let query = Query.make ~org_name ~project_number ~after:cursor in
    let* json = Github.run query in
    let cursor, project = Query.parse json in
    if List.length project.cards < 100 then
      Lwt.return { project with cards = acc @ project.cards }
    else aux (Some cursor) (acc @ project.cards)
  in
  aux None []

let get_all ~org_name project_numbers =
  Lwt_list.map_p
    (fun project_number -> get ~org_name ~project_number)
    project_numbers
