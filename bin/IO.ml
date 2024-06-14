open Caretaker
open Lwt.Syntax

let ( / ) = Filename.concat

let read_file f =
  let ic = open_in f in
  let s = really_input_string ic (in_channel_length ic) in
  close_in ic;
  s

let write_file f data =
  Fmt.pr "Writing %s\n%!" f;
  let dir = Filename.dirname f in
  (if not (Sys.file_exists dir) then
     let _ = Fmt.kstr Sys.command "mkdir -p %S" dir in
     ());
  let oc = open_out f in
  output_string oc data;
  flush oc;
  close_out oc

let write ~dir p =
  (* save what is needed to update offline *)
  let file = dir / Fmt.str "%s-%d.json" (Project.org p) (Project.number p) in
  let json = Project.to_json p in
  let data = Yojson.Safe.to_string ~std:true json in
  write_file file data

let read_timesheets ~years ~weeks ~users ~ids ~lint root =
  let weeks = Weeks.to_ints weeks in
  List.fold_left
    (fun acc year ->
      let root = root / string_of_int year in
      List.fold_left
        (fun acc week ->
          let dir = Fmt.str "%s/%02d" root week in
          if (not (Sys.file_exists dir)) || not (Sys.is_directory dir) then acc
          else
            let files =
              Sys.readdir dir |> Array.to_list
              |> List.filter (fun file -> String.ends_with ~suffix:".md" file)
              |> List.stable_sort String.compare
            in
            List.fold_left
              (fun acc file ->
                let path = dir / file in
                let str = read_file path in
                match
                  Report.of_markdown ~lint ~acc ~path ~year ~week ~users ~ids
                    str
                with
                | Ok r -> r
                | Error (`Msg x) ->
                    Fmt.epr "Error: %s\n%!" x;
                    acc)
              acc files)
        acc weeks)
    (Hashtbl.create 13) years

let read_timesheets_from_okr_updates d = read_timesheets (d / "team-weeklies")
let read_timesheets_from_admin d = read_timesheets (d / "weekly")

let err_okr_updates_dir () =
  invalid_arg
    "Missing path to tarides/okr-updates. Please use --okr-updates-dir \n\
     or set-up OKR_UPDATES_DIR to point to your local copy of the \n\
     tarides/okr-updates repositories."

let err_admin_dir () =
  invalid_arg
    "Missing path to tarides/admin. Please use --admin-dir or set-up ADMIN_DIR \n\
     to point to your local copy of the local tarides/admin repositories."

let get_okr_updates_dir = function
  | None -> err_okr_updates_dir ()
  | Some dir -> dir

let get_admin_dir = function None -> err_admin_dir () | Some dir -> dir

let get_timesheets ~lint
    {
      Common.data_dir;
      years;
      weeks;
      users;
      ids;
      source;
      okr_updates_dir;
      admin_dir;
      _;
    } =
  match source with
  | Local ->
      let file = data_dir / "timesheets.csv" in
      let data = read_file file in
      Report.of_csv ~years ~weeks ~users ~ids data
  | Okr_updates ->
      let dir = get_okr_updates_dir okr_updates_dir in
      read_timesheets_from_okr_updates ~years ~weeks ~users ~ids ~lint dir
  | Admin ->
      let dir = get_admin_dir admin_dir in
      read_timesheets_from_admin ~years ~weeks ~users ~ids ~lint dir
  | Github ->
      Fmt.epr "invalid source: cannot read timesheets on Github\n";
      exit 1

let get_goals ~org ~repo =
  let+ issues = Issue.list ~org ~repo () in
  Fmt.pr "Found %d goals in %s/%s.\n%!" (List.length issues) org repo;
  issues

let get_project
    {
      Common.data_dir;
      source;
      dry_run;
      project_number;
      items_per_page;
      org;
      project_goals;
      _;
    } =
  match (source, dry_run) with
  | Github, true -> Lwt.return (Project.empty org project_number)
  | Github, false ->
      let* goals = get_goals ~org ~repo:project_goals in
      let+ project =
        Project.get ~org ~project_number ~goals ?items_per_page ()
      in
      Fmt.epr "Found %d cards in %s/%d.\n%!"
        (List.length (Project.cards project))
        org project_number;
      project
  | Local, _ ->
      let file = data_dir / Fmt.str "%s-%d.json" org project_number in
      if not (Sys.file_exists file) then failwith "Run `caretaker fetch' first";
      let data = read_file file in
      let json = Yojson.Safe.from_string data in
      Lwt.return (Project.of_json json)
  | _ ->
      Fmt.epr "invalid source: cannot read project from %a\n" Common.pp_source
        source;
      exit 1
