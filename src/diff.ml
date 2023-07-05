open Lwt.Syntax

type item =
  | Item of { id : string; column : Column.t; set : string; github : string }
  | Warning of string

type t = (Card.t * item list) list

let starts ~id ?(github = "") set = Item { id; column = Starts; set; github }
let ends ~id ?(github = "") set = Item { id; column = Ends; set; github }
let title ~id ?(github = "") set = Item { id; column = Title; set; github }
let funder ~id ?(github = "") set = Item { id; column = Funder; set; github }

let schedule ~id ?(github = "") set =
  Item { id; column = Schedule; set; github }

let status ~id ?(github = "") set = Item { id; column = Status; set; github }

let objective ~id ?(github = "") set =
  Item { id; column = Objective; set; github }

let pp_item ppf = function
  | Item { id; column; set; github } ->
      Fmt.pf ppf
        "%s: column '%a' is out-of-sync.\n\
        \  - expected(DB): %S\n\
        \  - got(GitHub) : %S" id Column.pp column set github
  | Warning s -> Fmt.string ppf s

let pp = Fmt.Dump.(list (pair Card.pp (list pp_item)))

let diff_starts ~heatmap t =
  let id = Card.id t in
  let start_date = Heatmap.start_date heatmap id in
  let str = Fmt.to_to_string Heatmap.pp_start_date in
  match (start_date, Card.starts t) with
  | None, "" -> []
  | Some x, "" -> [ starts ~id (str x) ]
  | Some x, y ->
      let date = str x in
      if date <> y then [ starts ~id date ~github:y ] else []
  | None, x ->
      let msg =
        Fmt.str "%s was planning to start on %s but hasn't started yet " id x
      in
      [ Warning msg ]

let diff_ends ~heatmap t =
  let id = Card.id t in
  let end_date = Heatmap.end_date heatmap id in
  let str = Fmt.to_to_string Heatmap.pp_end_date in
  if Card.is_complete t || Card.is_dropped t then
    match (end_date, Card.ends t) with
    | None, "" -> []
    | Some x, "" -> [ ends ~id (str x) ]
    | Some x, y ->
        let date = str x in
        if date <> y then [ ends ~id date ~github:y ] else []
    | None, x ->
        let msg =
          Fmt.str "%s hasn't started by was planning to end on %s" id x
        in
        [ Warning msg ]
  else []

let diff_title ~(db : Okra.Masterdb.elt_t) t =
  let id = Card.id t in
  let github = Card.title t in
  if
    db.title = github
    || Fmt.str "%s: %s" id db.title = github
    || String.lowercase_ascii db.title = String.lowercase_ascii github
  then []
  else [ title ~id db.title ~github ]

let diff_objective ~(db : Okra.Masterdb.elt_t) t =
  let id = Card.id t in
  let github = Card.objective t in
  if db.objective <> github then [ objective ~id db.objective ~github ] else []

let diff_schedule ~(db : Okra.Masterdb.elt_t) t =
  let id = Card.id t in
  let github = Card.schedule t in
  let db = match db.schedule with None -> "" | Some s -> s in
  (* FIXME: fix the DB *)
  if db = "Rolling" then []
  else if String.starts_with ~prefix:db github then []
  else [ schedule ~id db ~github ]

let diff_status ~(db : Okra.Masterdb.elt_t) t =
  let id = Card.id t in
  let github = Card.status t in
  let db =
    match db.status with
    | None -> ""
    | Some s -> Okra.Masterdb.string_of_status s
  in
  (* FIXME: fix the DB *)
  let db = if db = "Wontfix" then "Dropped" else db in
  if String.starts_with ~prefix:db github then [] else [ status ~id db ~github ]

let diff_funder ~(db : Okra.Masterdb.elt_t) t =
  let id = Card.id t in
  let github = Card.funder t in
  let db =
    match db.reports with
    | [] -> ""
    | [ s ] -> s
    | l ->
        Fmt.epr "Warning: multiple funders for %s: %a\n" id
          Fmt.(list ~sep:(any ", ") string)
          l;
        List.hd l
  in
  (* FIXME: fix DB? *)
  let db =
    match db with
    | "js-community" -> "Jane Street - Community"
    | "js-commercial" -> "Jane Street - Commercial"
    | "tf" -> "Tezos"
    | _ -> db
  in
  if db = github then [] else [ funder ~id db ~github ]

let v ?db ?heatmap card =
  [
    ( card,
      (match heatmap with
      | None -> []
      | Some heatmap -> diff_starts ~heatmap card @ diff_ends ~heatmap card)
      @
      match db with
      | None -> []
      | Some db -> (
          match Okra.Masterdb.find_kr_opt db (Card.id card) with
          | None -> []
          | Some db ->
              diff_schedule ~db card @ diff_status ~db card
              @ diff_funder ~db card @ diff_title ~db card
              @ diff_objective ~db card) );
  ]

let concat = List.concat

let dry_run =
  match Sys.getenv "GH_DRYRUN" with
  | "" | "0" -> false
  | _ -> true
  | exception Not_found -> false

let skip item =
  match item with Item { column = Title | Objective; _ } -> true | _ -> false

let lint diff =
  List.iter
    (fun (_, items) ->
      List.iter (fun item -> Fmt.pr "%a\n%!" pp_item item) items)
    diff

let apply diff =
  Lwt_list.iter_s
    (fun (card, items) ->
      Lwt_list.iter_s
        (fun item ->
          if skip item then (
            Fmt.pr "SKIP: %a\n%!" pp_item item;
            Lwt.return ())
          else
            match item with
            | Warning _ -> Lwt.return_unit
            | Item { column; set; _ } ->
                let s = Card.graphql_mutate card column set in
                Fmt.pr "APPLY: %a\n%!" pp_item item;
                if dry_run then Lwt.return ()
                else
                  let+ _res = Github.run s in
                  ())
        items)
    diff
