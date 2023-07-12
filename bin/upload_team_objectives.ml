open Lwt.Syntax
open Caretaker

type entry = { objective : string; team : string; status : string }

let of_csv file =
  let ic = open_in file in
  let res = ref [] in
  let rows = Csv.of_channel ~has_header:true ic in
  let () =
    match Csv.Rows.header rows with
    | [ "Objective"; "Team"; "Status" ] -> ()
    | _ -> Fmt.invalid_arg "invalid headers"
  in
  Csv.Rows.iter
    ~f:(fun row ->
      match Csv.Row.to_list row with
      | [ o; t; s ] ->
          let e =
            {
              objective = String.trim o;
              team = String.trim t;
              status = String.trim s;
            }
          in
          res := e :: !res
      | l -> Fmt.epr "Warning; invalid line: %a\n" Fmt.(Dump.list string) l)
    rows;
  close_in ic;
  !res

let row e =
  [ (Column.of_string "status", e.status); (Column.of_string "team", e.team) ]

let update_project fields ~project_id ~card_id e =
  let row = row e in
  let+ _ = Card.Raw.update fields ~project_id ~card_id row in
  ()

let add_project fields ~project_id ~issue_id e =
  let row = row e in
  let+ _ = Card.Raw.add fields ~project_id ~issue_id row in
  ()

let create_issue ~org ~repo e =
  Issue.create ~org ~repo ~title:e.objective ~body:"" ()

let compare_issue x y =
  match String.compare (Issue.title x) (Issue.title y) with
  | 0 -> compare (Issue.number x) (Issue.number y)
  | i -> i

let find_duplicates ~org ~repo l =
  let l = List.sort compare_issue l in
  let rec aux = function
    | [] | [ _ ] -> ()
    | a :: b :: t ->
        if Issue.title a = Issue.title b then (
          assert (Issue.number b > Issue.number a);
          Fmt.pr "DUPLICATE: https://github.com/%s/%s/issues/%d\n%!" org repo
            (Issue.number b);
          aux (a :: t))
        else aux (b :: t)
  in
  aux l

let run ~force () =
  let entries = of_csv "input.csv" in
  let org = "tarides" in
  let repo = "goals" in
  let project_number = 27 in
  let* issues = Issue.list ~org ~repo () in
  let* project_id, fields = Project.get_id_and_fields ~org ~project_number in
  find_duplicates ~org ~repo issues;
  Lwt_list.iter_s
    (fun e ->
      match List.find_opt (fun i -> e.objective = Issue.title i) issues with
      | None ->
          let* i = create_issue ~org ~repo e in
          add_project fields ~project_id ~issue_id:(Issue.id i) e
      | Some _ -> if force then failwith "force: TODO" else Lwt.return ())
    entries

let () =
  Fmt_tty.setup_std_outputs ();
  Logs.set_level ~all:true (Some Logs.Debug);
  Lwt_main.run (run ~force:false ())
