module U = Yojson.Safe.Util

let ( / ) a b = U.member b a

type t = { id : string; title : string; cards : Card.t list }

let to_csv t =
  let headers = "Project" :: Card.csv_headers in
  let rows = List.map (fun card -> t.title :: Card.to_csv card) t.cards in
  let buffer = Buffer.create 10 in
  let out = Csv.to_buffer ~quote_all:true buffer in
  Csv.output_all out (headers :: rows);
  Csv.close_out out;
  Buffer.contents buffer

let graphql project_number =
  Fmt.str
    {|
    projectV2(number: %d) {
      id
      title
      items(first: 100) {
        nodes {
          %s
        }
      }
    }
    |}
    project_number Card.graphql

let parse json =
  let json = json / "data" / "organization" / "projectV2" in
  let id = json / "id" |> U.to_string in
  let title = json / "title" |> U.to_string in
  let cards = json / "items" / "nodes" |> U.to_list |> List.map Card.parse in
  { id; title; cards }

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
