module U = Yojson.Safe.Util

let ( / ) a b = U.member b a

type t = {
  org : string;
  number : int;
  title : string;
  cards : Card.t list;
  goals : Issue.t list;
  (* for mutations *)
  fields : Fields.t;
  project_id : string;
}

let v ?(title = "") ?(cards = []) ?(project_id = "") ?(goals = []) org number =
  { org; number; title; cards; fields = Fields.empty (); goals; project_id }

let empty org number = v org number
let cards t = t.cards
let org t = t.org
let number t = t.number
let fields t = t.fields
let project_id t = t.project_id

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

  let parse ?fields ~org ~project_number ~goals json =
    let json = json / "data" / "organization" / "projectV2" in
    let project_id = json / "id" |> U.to_string in
    let fields =
      match fields with None -> json / "fields" |> parse_fields | Some f -> f
    in
    let title = json / "title" |> U.to_string in
    let edges = json / "items" / "edges" |> U.to_list in
    match edges with
    | [] ->
        ( "",
          {
            org;
            project_id;
            title;
            cards = [];
            fields;
            goals;
            number = project_number;
          } )
    | edges ->
        let cursor = (List.rev edges |> List.hd) / "cursor" |> U.to_string in
        let cards =
          List.map
            (fun edge ->
              edge / "node" |> Card.parse_github_query ~project_id ~fields)
            edges
        in
        ( cursor,
          {
            org;
            project_id;
            title;
            cards;
            fields;
            number = project_number;
            goals;
          } )
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
  let cards = List.map Card.to_json t.cards in
  let goals = List.map Issue.to_json t.goals in
  `Assoc
    [
      ("org", `String t.org);
      ("number", `Int t.number);
      ("title", `String t.title);
      ("cards", `List cards);
      ("fields", fields);
      ("project-id", `String t.project_id);
      ("goals", `List goals);
    ]

let find_duplicates l =
  let title x = String.lowercase_ascii (Issue.title x) in
  let compare_issue x y =
    match String.compare (title x) (title y) with
    | 0 -> compare (Issue.number x) (Issue.number y)
    | i -> i
  in
  let l = List.sort compare_issue l in
  let rec aux = function
    | [] | [ _ ] -> ()
    | a :: b :: t ->
        if title a = title b then (
          assert (Issue.number b > Issue.number a);
          Fmt.pr "DUPLICATE GOAL: %s\n%!" (Issue.url b);
          aux (a :: t))
        else aux (b :: t)
  in
  aux l

let goals g =
  let h = Hashtbl.create 13 in
  let title i = String.lowercase_ascii (Issue.title i) in
  List.iter (fun i -> Hashtbl.add h (title i) i) g;
  h

let find_non_existing_goals g cards =
  let goals = goals g in
  List.iter
    (fun c ->
      match String.lowercase_ascii (Card.objective c) with
      | "" -> ()
      | s -> (
          match Hashtbl.find_opt goals s with
          | None ->
              Fmt.pr "GOAL NOT FOUND: %s (%s)\n%!" (Card.objective c)
                (Card.id c)
          | Some _ -> ()))
    cards

let of_json json =
  let number = json / "number" |> U.to_int in
  let title = json / "title" |> U.to_string in
  let fields = json / "fields" |> Fields.of_json in
  let project_id = json / "project-id" |> U.to_string in
  let org = json / "org" |> U.to_string in
  let cards =
    json / "cards" |> U.to_list |> List.map (Card.of_json ~fields ~project_id)
  in
  let goals = json / "goals" |> U.to_list |> List.map Issue.of_json in
  find_duplicates goals;
  find_non_existing_goals goals cards;
  { org; number; title; fields; cards; project_id; goals }

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

let diff ?heatmap (t : t) =
  let diffs = List.map (Diff.of_card ?heatmap) t.cards in
  let goals = List.map (Diff.of_goal t.cards) t.goals in
  let diffs = Diff.concat (goals @ diffs) in
  diffs

let sync ?heatmap t = Diff.apply (diff ?heatmap t)
let lint ?heatmap t = Diff.lint (diff ?heatmap t)

let get ~goals ~org ~project_number () =
  find_duplicates goals;
  let open Lwt.Syntax in
  let rec aux fields cursor acc =
    let query = Query.make ~org ~project_number ~after:cursor in
    let* json = Github.run query in
    let cursor, project =
      Query.parse ?fields ~project_number ~org ~goals json
    in
    if List.length project.cards < 100 then
      Lwt.return { project with cards = acc @ project.cards }
    else aux (Some project.fields) (Some cursor) (acc @ project.cards)
  in
  let+ t = aux None None [] in
  find_non_existing_goals t.goals t.cards;
  t

let get_project_id_and_fields ~org ~project_number =
  let open Lwt.Syntax in
  let query = Query.make ~org ~project_number ~after:None in
  let+ json = Github.run query in
  let _, project = Query.parse ~project_number ~org ~goals:[] json in
  (project.project_id, project.fields)
