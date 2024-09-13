open Lwt.Syntax
open Caretaker

type entry = {
  title : string;
  id : string;
  team : string;
  pillar : string;
  status : string;
  schedule : string;
  funder : string;
  stakeholder : string;
  tracked_by : Issue.t option;
  category : string;
}

let normalise = function
  | "Compiler & Language" -> "Compiler and language"
  | "N/A" | "#N/A" -> ""
  | "tf" | "tf-multicore" -> "Tezos"
  | "nk" -> "Nitrokey"
  | "OCaml Adoption & Community" -> "ocaml.org"
  | "Jane Street - Community, tf-multicore" | "Jane Street - Community, tf" ->
      "Jane Street - Community"
  | "Wontfix" -> "Dropped"
  | "Completed" -> "Complete"
  | s -> s

let normalise_pillar = function
  | "MirageOS" | "Mirage" -> "ecosystem"
  | s -> normalise s

let of_csv ~goals file =
  let goals =
    let h = Hashtbl.create 13 in
    List.iter (fun i -> Hashtbl.add h (Issue.title i) i) goals;
    h
  in
  let ic = open_in file in
  let res = ref [] in
  let rows = Csv.of_channel ~has_header:true ic in
  let () =
    match Csv.Rows.header rows with
    | [
     "Title";
     "ID";
     "Team";
     _;
     (* XXX: there's a typo in the CSV pilar/pillar *)
     "Status";
     "Schedule";
     "Funder";
     "Stakeholder";
     "Tracked by";
     "Category";
    ] ->
        ()
    | _ -> Fmt.invalid_arg "invalid headers"
  in
  Csv.Rows.iter
    ~f:(fun row ->
      match Csv.Row.to_list row with
      | [
       title;
       id;
       team;
       pillar;
       status;
       schedule;
       funder;
       stakeholder;
       tracked_by;
       category;
      ] ->
          let tracked_by =
            match Hashtbl.find_opt goals (String.trim tracked_by) with
            | None -> None
            | Some i -> Some i
          in
          let e =
            {
              title = String.trim title;
              id = String.trim id;
              team = normalise (String.trim team);
              pillar = normalise_pillar (String.trim pillar);
              status = normalise (String.trim status);
              schedule = String.trim schedule;
              funder = normalise (String.trim funder);
              stakeholder = String.trim stakeholder;
              tracked_by;
              category = String.trim category;
            }
          in
          res := e :: !res
      | l -> Logs.warn (fun m -> m "Invalid line: %a" Fmt.(Dump.list string) l))
    rows;
  close_in ic;
  !res

let row e =
  [
    (Column.of_string "title", e.title);
    (Column.of_string "id", e.id);
    (Column.of_string "team", e.team);
    (Column.of_string "pillar", e.pillar);
    (Column.of_string "status", e.status);
    (Column.of_string "schedule", e.schedule);
    (Column.of_string "funder", e.funder);
    (Column.of_string "stakeholder", e.stakeholder);
    ( Column.of_string "Tracked by",
      match e.tracked_by with None -> "" | Some i -> Issue.id i );
    (Column.of_string "category", e.category);
  ]

let row_of_card c =
  [
    (Column.of_string "title", Card.title c);
    (Column.of_string "id", Card.id c);
    (Column.of_string "team", Card.team c);
    (Column.of_string "pillar", Card.pillar c);
    (Column.of_string "status", Card.status c);
    (Column.of_string "iteration", Card.iteration c);
    (Column.of_string "funder", Card.funder c);
    (Column.of_string "stakeholder", Card.stakeholder c);
    (Column.of_string "Tracked by", Card.tracked_by c);
    (Column.of_string "category", Card.category c);
  ]

let card_is_up_to_date c e =
  let id = e.id in
  let e = row e in
  let c = row_of_card c in
  let same =
    List.for_all2
      (fun (a, b) (c, d) ->
        assert (a = c);
        Fields.same b d)
      e c
  in
  (if not same then
     let diff =
       List.map2
         (fun (a, b) (c, d) ->
           assert (a = c);
           if Fields.same b d then [] else [ (a, (b, d)) ])
         e c
       |> List.flatten
     in
     Logs.debug (fun m ->
         m "DIFF(%s): %a" id
           Fmt.Dump.(list (pair Column.pp (pair string string)))
           diff));
  same

let update_project fields ~project_id ~card_id e =
  let row = row e in
  let+ _ = Card.Raw.update fields ~project_id ~card_id row in
  ()

let add_project fields ~project_id ~issue_id e =
  let row = row e in
  let+ _ = Card.Raw.add fields ~project_id ~issue_id row in
  ()

let title e = Fmt.str "%s: %s" e.id e.title

let create_issue ~org ~repo e =
  let title = e.title in
  Issue.create ~org ~repo ~title ~body:"" ()

let find_duplicate_cards l =
  let compare_card x y =
    match String.compare (Card.id x) (Card.title y) with
    | 0 -> compare (Card.title x) (Card.title y)
    | i -> i
  in
  let l = List.sort compare_card l in
  let rec aux = function
    | [] | [ _ ] -> ()
    | a :: b :: t ->
        if Card.id a = Card.id b then (
          Logs.debug (fun m -> m "DUPLICATE: %s" (Card.id b));
          aux (a :: t))
        else aux (b :: t)
  in
  aux l

let find_duplicate_objectives ~org ~repo l =
  let compare_issue x y =
    match String.compare (Issue.title x) (Issue.title y) with
    | 0 -> compare (Issue.number x) (Issue.number y)
    | i -> i
  in
  let l = List.sort compare_issue l in
  let rec aux = function
    | [] | [ _ ] -> ()
    | a :: b :: t ->
        if Issue.title a = Issue.title b then (
          assert (Issue.number b > Issue.number a);
          Logs.debug (fun m ->
              m "DUPLICATE: https://github.com/%s/%s/issues/%d" org repo
                (Issue.number b));
          aux (a :: t))
        else aux (b :: t)
  in
  aux l

let find_same_card cards e = List.find_opt (fun i -> e.id = Card.id i) cards

let find_same_issue issues e =
  List.find_opt
    (fun i -> e.title = Issue.title i || title e = Issue.title i)
    issues

let goals () =
  let org = "tarides" in
  let repo = "goals" in
  let+ issues = Issue.list ~org ~repo () in
  find_duplicate_objectives ~org ~repo issues;
  issues

module Tbl = Hashtbl.Make (struct
  type t = Issue.t

  let hash t = Hashtbl.hash (Issue.id t)
  let equal x y = Issue.id x = Issue.id y
end)

let update_tracked_by tracked_by =
  let tracked_by : string list Tbl.t =
    let h = Tbl.create 13 in
    List.iter
      (function
        | i, url ->
            let tracks =
              match Tbl.find_opt h i with None -> [] | Some ts -> ts
            in
            Tbl.replace h i (url :: tracks))
      tracked_by;
    h
  in
  let to_update =
    Tbl.fold
      (fun i new_tracks acc ->
        let old_tracks = Issue.tracks i in
        let tracks = List.sort_uniq String.compare (old_tracks @ new_tracks) in
        let i' = Issue.with_tracks i tracks in
        if i = i' then acc else i' :: acc)
      tracked_by []
  in
  let+ () =
    Lwt_list.iter_s
      (fun i ->
        Logs.debug (fun m ->
            m "XXX UPDATE TRACKED BY: %a -> %a" Issue.pp i
              Fmt.(Dump.list string)
              (Issue.tracks i));
        Issue.update i)
      to_update
  in
  ()

let run ~force () =
  let file = "roadmap.csv" in
  Logs.debug (fun m -> m "Reading %s.." file);
  let* goals = goals () in
  let entries = of_csv ~goals file in
  let org = "tarides" in
  let repo = "roadmap" in
  let project_number = 25 in
  let* project = Project.get ~goals ~org ~project_number () in
  let cards = Project.cards project in
  let* issues = Issue.list ~org ~repo () in
  let fields = Project.fields project in
  let project_id = Project.project_id project in
  find_duplicate_cards cards;

  let entries = List.map (fun e -> (e, find_same_card cards e)) entries in

  let n_add =
    List.fold_left
      (fun acc (_, c) -> match c with None -> succ acc | Some _ -> acc)
      0 entries
  in
  let count = ref 0 in
  Logs.debug (fun m -> m "Adding %d new cards..." n_add);
  let* () =
    Lwt_list.iter_s
      (fun (e, c) ->
        match c with
        | Some c ->
            if force then
              (* FIXME: update the 'tracked-by' field with the API
                   when available. *)
              let _ = e.tracked_by in
              if card_is_up_to_date c e then Lwt.return ()
              else (
                Logs.debug (fun m -> m "UPDATE: [%s] %s" e.id e.title);
                let _ =
                  update_project
                  (* fields ~project_id ~card_id:(Card.uuid c) e *)
                in
                Lwt.return ())
            else Lwt.return ()
        | None ->
            incr count;
            Logs.debug (fun m ->
                m "ADD(%d/%d): [%s] %s" !count n_add e.id e.title);
            let* issue =
              match find_same_issue issues e with
              | Some i -> Lwt.return i
              | None -> create_issue ~org ~repo e
            in
            add_project fields ~project_id ~issue_id:(Issue.id issue) e)
      entries
  in
  let tracked_by =
    List.fold_left
      (fun acc (e, c) ->
        match (e.tracked_by, c) with
        | None, _ -> acc
        | Some _, None ->
            (* FIXME: need to run that stuff twice...*)
            Logs.debug (fun m -> m "XXX please run that command once more...");
            acc
        | Some i, Some c -> (i, Card.issue_url c) :: acc)
      [] entries
  in
  update_tracked_by tracked_by

let () =
  Fmt_tty.setup_std_outputs ();
  Logs.set_level ~all:true (Some Logs.Debug);
  Lwt_main.run (run ~force:true ())
