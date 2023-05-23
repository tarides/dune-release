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

let order_by_fn (pivot : Column.t) cards =
  let sections = Hashtbl.create 12 in
  List.iter
    (fun card ->
      let name = Card.get card pivot in
      let others =
        match Hashtbl.find_opt sections name with None -> [] | Some l -> l
      in
      Hashtbl.replace sections name (card :: others))
    cards;
  Hashtbl.fold (fun k v acc -> (k, v) :: acc) sections []

let filter_out_fn f cards =
  List.fold_left
    (fun acc card ->
      let matching = Card.filter_out f card in
      if matching then acc else card :: acc)
    [] cards

let pp ?(order_by = Column.Objective) ?(filter_out = Filter.default_out) ppf t =
  Fmt.pf ppf "\n== %s (%s) ==\n" t.title t.id;
  let sections = filter_out_fn filter_out t.cards in
  let sections = order_by_fn order_by sections in
  if List.compare_length_with sections 1 = 0 then
    List.iter (Card.pp ppf) t.cards
  else
    List.iter
      (fun (name, section) ->
        Fmt.pf ppf "\n - %s -\n" name;
        List.iter (Card.pp ppf) section)
      sections
