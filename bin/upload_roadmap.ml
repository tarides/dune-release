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
  tracked_by : string;
  category : string;
}

let normalise = function
  | "Compiler & Language" -> "Compiler and language"
  | "N/A" | "#N/A" -> ""
  | s -> s

let of_csv file =
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
          let e =
            {
              title = String.trim title;
              id = String.trim id;
              team = normalise (String.trim team);
              pillar = normalise (String.trim pillar);
              status = String.trim status;
              schedule = String.trim schedule;
              funder = normalise (String.trim funder);
              stakeholder = String.trim stakeholder;
              tracked_by = String.trim tracked_by;
              category = String.trim category;
            }
          in
          res := e :: !res
      | l -> Fmt.epr "Warning; invalid line: %a\n" Fmt.(Dump.list string) l)
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
    (Column.of_string "Tracked by", e.tracked_by);
    (Column.of_string "category", e.category);
  ]

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
  let title = title e in
  Issue.create ~org ~repo ~title ~body:"" ()

let compare_card x y = String.compare (Card.id x) (Card.title y)

let find_duplicates l =
  let l = List.sort compare_card l in
  let rec aux = function
    | [] | [ _ ] -> ()
    | a :: b :: t ->
        if Card.id a = Card.id b then (
          Fmt.pr "DUPLICATE: %s\n%!" (Card.id b);
          aux (a :: t))
        else aux (b :: t)
  in
  aux l

let find_same_card cards e = List.find_opt (fun i -> e.id = Card.id i) cards

let find_same_issue issues e =
  List.find_opt
    (fun i -> e.title = Issue.title i || title e = Issue.title i)
    issues

let run ~force () =
  let file = "roadmap.csv" in
  Fmt.pr "Reading %s..\n" file;
  let entries = of_csv file in
  let org = "tarides" in
  let repo = "roadmap" in
  let project_number = 25 in
  let* project = Project.get ~org ~project_number () in
  let cards = Project.cards project in
  let* issues = Issue.list ~org ~repo () in
  let fields = Project.fields project in
  let project_id = Project.id project in
  find_duplicates cards;
  Lwt_list.iter_s
    (fun e ->
      let* issue =
        match find_same_issue issues e with
        | Some i -> Lwt.return i
        | None -> create_issue ~org ~repo e
      in
      let+ () =
        match find_same_card cards e with
        | Some c ->
            if force then
              update_project fields ~project_id ~card_id:(Card.id c) e
            else Lwt.return ()
        | None -> add_project fields ~project_id ~issue_id:(Issue.id issue) e
      in
      ())
    [ List.hd entries ]

let () =
  Fmt_tty.setup_std_outputs ();
  Logs.set_level ~all:false (Some Logs.Debug);
  Lwt_main.run (run ~force:true ())
