open Lwt.Syntax

type item =
  | Item of { id : string; column : Column.t; set : string; github : string }
  | Tracked_by of {
      id : string;
      url : string;
      set : Issue.t option;
      github : Issue.t option;
    }
  | State of {
      id : string;
      issue_id : string;
      status : string;
      set : [ `Open | `Closed ];
    }
  | Warning of string

type t = (Card.t * item list) list

let same_title x y = String.lowercase_ascii x = String.lowercase_ascii y
let starts ~id ?(github = "") set = Item { id; column = Starts; set; github }
let ends ~id ?(github = "") set = Item { id; column = Ends; set; github }
let title ~id ?(github = "") set = Item { id; column = Title; set; github }
let funder ~id ?(github = "") set = Item { id; column = Funder; set; github }

let schedule ~id ?(github = "") set =
  Item { id; column = Schedule; set; github }

let status ~id ?(github = "") set = Item { id; column = Status; set; github }

let objective ?goals ~id ~url ?(github = "") set =
  let goals = match goals with None -> Hashtbl.create 1 | Some h -> h in
  let find msg x =
    match x with
    | "" -> None
    | _ -> (
        let l = String.lowercase_ascii x in
        match Hashtbl.find_opt goals l with
        | None -> Fmt.failwith "unknown goal for card %s in %s: %s\n%!" id msg x
        | Some i -> Some i)
  in

  let set = find "DB" set in
  let github = find "Github" github in
  Tracked_by { id; url; set; github }

let pp_item ppf = function
  | Item { id; column; set; github } ->
      Fmt.pf ppf
        "%s: column '%a' is out-of-sync.\n\
        \  - expected(DB): %S\n\
        \  - got(GitHub) : %S" id Column.pp column set github
  | Tracked_by { id; set; github; _ } ->
      let pp ppf = function
        | None -> Fmt.pf ppf "<none>"
        | Some i -> Fmt.string ppf (Issue.url i)
      in
      Fmt.pf ppf
        "%s: column '%a' is out-of-sync.\n\
        \  - expected(DB): %a\n\
        \  - got(GitHub) : %a" id Column.pp Objective pp set pp github
  | State { id; status; set; _ } ->
      Fmt.pf ppf "%s: state is out-of-sync.\n  - status: %S\n  - expected: %s"
        id status
        (match set with `Open -> "open" | `Closed -> "closed")
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
  if not (Card.is_active t) then
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
    same_title db.title github
    || same_title (Fmt.str "%s: %s" id db.title) github
  then []
  else [ title ~id db.title ~github ]

let diff_objective ?goals ~(db : Okra.Masterdb.elt_t) t =
  let id = Card.id t in
  let github = Card.objective t in
  let url = Card.issue_url t in
  if same_title db.objective github then []
  else [ objective ?goals ~id ~url db.objective ~github ]

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

let diff_state t =
  let id = Card.id t in
  let status = Card.status t in
  let closed = Card.issue_closed t in
  let issue_id = Card.issue_id t in
  let set = if Card.is_active t then `Open else `Closed in
  match (closed, set) with
  | true, `Closed | false, `Open -> []
  | _ -> [ State { id; issue_id; status; set } ]

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
    | "tf" | "tf-multicore" -> "Tezos"
    | "nk" -> "Nitrokey"
    | _ -> db
  in
  if same_title db github then [] else [ funder ~id db ~github ]

let v ?db ?heatmap ?goals card =
  [
    ( card,
      diff_state card
      @ (match heatmap with
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
              @ diff_objective ?goals ~db card) );
  ]

let concat = List.concat

let dry_run =
  match Sys.getenv "GH_DRYRUN" with
  | "" | "0" -> false
  | _ -> true
  | exception Not_found -> false

let skip item =
  match item with
  | Item { column = Title | Objective | Status; _ } -> true
  | _ -> false

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
            | State { issue_id; set; _ } ->
                let s = Issue.update_state ~issue_id set in
                if dry_run then Lwt.return ()
                else
                  let+ _ = Github.run s in
                  ()
            | Tracked_by { url; set = Some issue; github = None; _ } ->
                let tracks = Issue.tracks issue in
                let issue' = Issue.with_tracks issue (url :: tracks) in
                if dry_run then Lwt.return ()
                else (
                  Fmt.pr "APPLY %a\n%!" pp_item item;
                  let+ _res = Issue.update issue' in
                  Issue.copy_tracks ~dst:issue ~src:issue';
                  ())
            | Tracked_by _ ->
                Fmt.pr "SKIP: %a\n%!" pp_item item;
                Lwt.return ()
            | Item { column = Objective; _ }
            | Item { column = Title; _ }
            | Item { column = Status; _ } ->
                assert false
            | Item { column; set; _ } ->
                let s = Card.graphql_mutate card column set in
                if dry_run then Lwt.return ()
                else (
                  Fmt.pr "APPLY: %a\n%!" pp_item item;
                  let+ _res = Github.run s in
                  ()))
        items)
    diff
