open Lwt.Syntax

type card =
  | Column of { card : Card.t; column : Column.t; set : string; old : string }
  | State of { card : Card.t; set : [ `Open | `Closed ] }
  | Tracked_by of {
      card : Card.t;
      url : string;
      set : Issue.t option;
      github : Issue.t option;
    }

type issue = State of { issue : Issue.t; set : [ `Open | `Closed ] }
type item = Card of card | Issue of issue | Warning of string

let card_of_item = function
  | Issue _ | Warning _ -> None
  | Card (Column { card; _ } | State { card; _ } | Tracked_by { card; _ }) ->
      Some card

let card_column card column ~set ~old =
  [ Card (Column { card; column; set; old }) ]

let card_state card ~set = [ Card (State { card; set }) ]
let issue_state issue ~set = [ Issue (State { issue; set }) ]

type t = item list

let empty = []
let same_title x y = String.lowercase_ascii x = String.lowercase_ascii y
let starts ~card ?(old = "") set = card_column card Starts ~set ~old
let ends ~card ?(old = "") set = card_column card Ends ~set ~old
let title ~card ?(old = "") set = card_column card Title ~set ~old
let funder ~card ?(old = "") set = card_column card Funder ~set ~old
let schedule ~card ?(old = "") set = card_column card Schedule ~set ~old
let status ~card ?(old = "") set = card_column card Status ~set ~old

let objective ?goals ~card ~url ?(github = "") set =
  let goals = match goals with None -> Hashtbl.create 1 | Some h -> h in
  let find msg x =
    match x with
    | "" -> None
    | _ -> (
        let l = String.lowercase_ascii x in
        match Hashtbl.find_opt goals l with
        | None ->
            Fmt.failwith "unknown goal for card %s in %s: %s\n%!" (Card.id card)
              msg x
        | Some i -> Some i)
  in

  let set = find "DB" set in
  let github = find "Github" github in
  [ Card (Tracked_by { card; url; set; github }) ]

let state_of_closed b = if b then "Closed" else "Open"

let pp_card_item ppf = function
  | Column { card; column; set; old } ->
      let id = Card.id card in
      Fmt.pf ppf
        "%s: column '%a' is out-of-sync.\n\
        \  - expected(DB): %S\n\
        \  - got(GitHub) : %S" id Column.pp column set old
  | Tracked_by { card; set; github; _ } ->
      let pp ppf = function
        | None -> Fmt.pf ppf "<none>"
        | Some i -> Fmt.string ppf (Issue.url i)
      in
      Fmt.pf ppf
        "%s: column '%a' is out-of-sync.\n\
        \  - expected(DB): %a\n\
        \  - got(GitHub) : %a" (Card.id card) Column.pp Objective pp set pp
        github
  | State { card; set; _ } ->
      let status = Card.status card in
      Fmt.pf ppf
        "%s [%s]: state is out-of-sync.\n  - status: %S\n  - expected: %s"
        (Card.issue_url card) (Card.id card) status
        (match set with `Open -> "open" | `Closed -> "closed")

let pp_issue_item ppf = function
  | State { issue; set; _ } ->
      let current = state_of_closed (Issue.closed issue) in
      let set = match set with `Open -> "open" | `Closed -> "closed" in
      Fmt.pf ppf
        "%s [%s]: state is out-of-sync.\n  - current: %S\n  - expected: %s"
        (Issue.url issue) (Issue.title issue) current set

let pp_item ppf = function
  | Card c -> pp_card_item ppf c
  | Issue i -> pp_issue_item ppf i
  | Warning s -> Fmt.string ppf s

let pp = Fmt.Dump.(list pp_item)

let diff_starts ~heatmap t =
  let id = Card.id t in
  let start_date = Heatmap.start_date heatmap id in
  let str = Fmt.to_to_string Heatmap.pp_start_date in
  match (start_date, Card.starts t) with
  | None, "" -> []
  | Some x, "" -> starts ~card:t (str x)
  | Some x, y ->
      let date = str x in
      if date <> y then starts ~card:t date ~old:y else []
  | None, x ->
      let msg =
        Fmt.str "%s was planning to start on %s but hasn't started yet " id x
      in
      [ Warning msg ]

let diff_ends ~heatmap t =
  let id = Card.id t in
  let end_date = Heatmap.end_date heatmap id in
  let str = Fmt.to_to_string Heatmap.pp_end_date in
  if not (Card.should_be_open t) then
    match (end_date, Card.ends t) with
    | None, "" -> []
    | Some x, "" -> ends ~card:t (str x)
    | Some x, y ->
        let date = str x in
        if date <> y then ends ~card:t date ~old:y else []
    | None, x ->
        let msg =
          Fmt.str "%s hasn't started by was planning to end on %s" id x
        in
        [ Warning msg ]
  else []

let diff_title ~(db : Okra.Masterdb.elt_t) t =
  let id = Card.id t in
  let old = Card.title t in
  if same_title db.title old || same_title (Fmt.str "%s: %s" id db.title) old
  then []
  else title ~card:t db.title ~old

let diff_objective ?goals ~(db : Okra.Masterdb.elt_t) t =
  let github = Card.objective t in
  let url = Card.issue_url t in
  if same_title db.objective github then []
  else objective ?goals ~card:t ~url db.objective ~github

let diff_schedule ~(db : Okra.Masterdb.elt_t) t =
  let old = Card.schedule t in
  let db = match db.schedule with None -> "" | Some s -> s in
  (* FIXME: fix the DB *)
  if db = "Rolling" then []
  else if String.starts_with ~prefix:db old then []
  else schedule ~card:t db ~old

let diff_status ~(db : Okra.Masterdb.elt_t) t =
  let old = Card.status t in
  let db =
    match db.status with
    | None -> ""
    | Some s -> Okra.Masterdb.string_of_status s
  in
  (* FIXME: fix the DB *)
  let db = if db = "Wontfix" then "Dropped" else db in
  if String.starts_with ~prefix:db old then [] else status ~card:t db ~old

let diff_state t =
  let closed = Card.issue_closed t in
  let set = if Card.should_be_open t then `Open else `Closed in
  match (closed, set) with
  | true, `Closed | false, `Open -> []
  | _ -> card_state t ~set

let diff_funder ~(db : Okra.Masterdb.elt_t) t =
  let old = Card.funder t in
  let db = db.funder in
  if same_title db old then [] else funder ~card:t db ~old

let of_card ?db ?heatmap ?goals card =
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
          diff_schedule ~db card @ diff_status ~db card @ diff_funder ~db card
          @ diff_title ~db card
          @ diff_objective ?goals ~db card)

let of_goal cards goal =
  let tracks = Issue.tracks goal in
  let tracks =
    List.fold_left
      (fun acc url ->
        match List.find_opt (fun c -> Card.issue_url c = url) cards with
        | None -> acc
        | Some s -> s :: acc)
      [] (List.rev tracks)
  in
  match tracks with
  | [] -> []
  | _ ->
      let active = List.exists (fun i -> not (Card.issue_closed i)) tracks in
      let set = if active then `Open else `Closed in
      if active <> Issue.closed goal then [] else issue_state goal ~set

let concat = List.concat

let dry_run =
  match Sys.getenv "GH_DRYRUN" with
  | "" | "0" -> false
  | _ -> true
  | exception Not_found -> false

let skip = function
  | Card (Column { column = Title | Objective | Status; _ }) -> true
  | _ -> false

let lint diff =
  let teams = Hashtbl.create 13 in
  List.iter
    (fun i ->
      let team =
        match card_of_item i with
        | None -> "???"
        | Some c -> ( match Card.team c with "" -> "???" | x -> x)
      in
      let cards =
        match Hashtbl.find_opt teams team with None -> [] | Some cs -> cs
      in
      Hashtbl.replace teams team (i :: cards))
    diff;
  Hashtbl.iter
    (fun team items ->
      Fmt.pr "\n\n--- %s ---\n\n" team;
      List.iter (fun i -> Fmt.pr "%a\n" pp_item i) items)
    teams

let apply diff =
  Lwt_list.iter_s
    (fun item ->
      if skip item then (
        Fmt.pr "SKIP: %a\n%!" pp_item item;
        Lwt.return ())
      else
        match item with
        | Warning _ -> Lwt.return_unit
        | Issue (State { issue; set; _ }) ->
            let issue_id = Issue.id issue in
            let s = Issue.update_state ~issue_id set in
            if dry_run then Lwt.return ()
            else
              let+ _ = Github.run s in
              ()
        | Card (State { card; set; _ }) ->
            let issue_id = Card.issue_id card in
            let s = Issue.update_state ~issue_id set in
            if dry_run then Lwt.return ()
            else (
              Fmt.pr "SKIP: update %s (%s)\n" (Card.issue_url card)
                (Card.title card);
              let+ _ = Github.run s in
              ())
        | Card (Tracked_by { url; set = Some issue; github = None; _ }) ->
            let tracks = Issue.tracks issue in
            let issue' = Issue.with_tracks issue (url :: tracks) in
            if dry_run then Lwt.return ()
            else (
              Fmt.pr "APPLY %a\n%!" pp_item item;
              let+ _res = Issue.update issue' in
              Issue.copy_tracks ~dst:issue ~src:issue';
              ())
        | Card (Tracked_by _) ->
            Fmt.pr "SKIP: %a\n%!" pp_item item;
            Lwt.return ()
        | Card (Column { column = Objective; _ })
        | Card (Column { column = Title; _ })
        | Card (Column { column = Status; _ }) ->
            assert false
        | Card (Column { card; column; set; _ }) ->
            let s = Card.graphql_mutate card column set in
            if dry_run then Lwt.return ()
            else (
              Fmt.pr "APPLY: %a\n%!" pp_item item;
              let+ _res = Github.run s in
              ()))
    diff
