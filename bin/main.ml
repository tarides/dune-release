open Caretaker
open Common
open Lwt.Syntax
module U = Yojson.Safe.Util

let ( / ) = Filename.concat

type t = { org : string; project : Project.t }

let pp ppf t =
  Fmt.pf ppf "org: %s\n" t.org;
  Project.pp ppf t.project

let pp_csv headers ppf t = Fmt.string ppf (Project.to_csv ~headers t.project)
let pp_csv_ts ppf t = Fmt.string ppf (Report.to_csv t)

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

let filter ?filter_out data =
  let filter = Project.filter ?filter_out in
  { data with project = filter data.project }

type format = { style : [ `Plain | `CSV ]; fields : Column.t list }

let out ~format t =
  match format.style with
  | `Plain -> Fmt.pr "%a\n%!" pp t
  | `CSV -> Fmt.pr "%a%!" (pp_csv format.fields) t

let write ~dir t =
  (* save what is needed to update offline *)
  let file =
    dir
    / Fmt.str "%s-%d.json" (Project.org t.project) (Project.number t.project)
  in
  let json = Project.to_json t.project in
  let data = Yojson.Safe.to_string ~std:true json in
  write_file file data

let lint_project ?heatmap t = Project.lint ?heatmap t.project
let out_timesheets t = Fmt.pr "%a%!" pp_csv_ts t

let out_heatmap ~format t =
  match format.style with
  | `Plain -> Fmt.pr "%a\n%!" Heatmap.pp t
  | `CSV -> Fmt.pr "%s%!" (Heatmap.to_csv t)

let write_timesheets ~dir t =
  let file = dir / "timesheets.csv" in
  let data = Fmt.str "%a" pp_csv_ts t in
  write_file file data

open Cmdliner

let all =
  let doc =
    Arg.info ~doc:"Show all items (by default, just show open cards and issues"
      [ "all" ]
  in
  Arg.(value @@ flag doc)

let style =
  Arg.(
    value
    @@ opt (enum [ ("plain", `Plain); ("csv", `CSV) ]) `Plain
    @@ info ~doc:"The output format" [ "format"; "f" ])

let fields =
  let default = Card.default_csv_headers in
  let column = Arg.conv ((fun str -> Ok (Column.of_string str)), Column.pp) in
  Arg.(
    value
    @@ opt (list column) default
    @@ info ~doc:"What fields to use (in the CSV file)." [ "fields" ])

let format =
  Term.(const (fun style fields -> { style; fields }) $ style $ fields)

let timesheets_term =
  Arg.(value @@ flag @@ info ~doc:"Display timesheet reports" [ "timesheets" ])

let heatmap_term =
  Arg.(value @@ flag @@ info ~doc:"Display heatmap reports" [ "heatmap" ])

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

let get_timesheets ~years ~weeks ~users ~ids ~lint ~data_dir ~okr_updates_dir
    ~admin_dir = function
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
  | Github -> failwith "invalid source: cannot read timesheets on Github"

let get_goals org repo =
  let+ issues = Issue.list ~org ~repo () in
  Fmt.pr "Found %d goals in %s/%s.\n%!" (List.length issues) org repo;
  issues

let get_project ?items_per_page org goals project_number data_dir dry_run source
    =
  match (source, dry_run) with
  | Github, true -> Lwt.return (Project.empty org project_number)
  | Github, false ->
      let* goals = get_goals org goals in
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
  | _ -> failwith "invalid source"

let fetch =
  let run () org goals project_number okr_updates_dir admin_dir data_dir years
      weeks users ids dry_run source items_per_page =
    Lwt_main.run
    @@
    let () =
      let source =
        match (source, okr_updates_dir, admin_dir) with
        | Github, Some dir, _ ->
            Fmt.epr "Reading timesheets from `%s'.\n%!" dir;
            Okr_updates
        | Github, _, Some dir ->
            Fmt.epr "Reading timesheets from `%s'.\n%!" dir;
            Admin
        | Github, _, _ ->
            Fmt.epr "Skipping timesheets.\n%!";
            source
        | _ -> source
      in
      (* fetch timesheets *)
      match source with
      | Local | Github -> ()
      | _ ->
          let report =
            get_timesheets ~years ~weeks ~users ~ids ~admin_dir ~okr_updates_dir
              ~data_dir ~lint:false source
          in
          write_timesheets ~dir:data_dir report
    in
    let+ () =
      (* fetch project boards *)
      match (source, dry_run) with
      | Github, true ->
          let project = Project.empty org project_number in
          write ~dir:data_dir { org; project };
          Lwt.return ()
      | Github, false ->
          let* goals = get_goals org goals in
          let+ project =
            Project.get ~goals ~org ~project_number ?items_per_page ()
          in
          Fmt.epr "Found %d cards in %s/%d.\n%!"
            (List.length (Project.cards project))
            org project_number;
          write ~dir:data_dir { org; project }
      | _ -> Lwt.return ()
    in
    ()
  in
  Cmd.v (Cmd.info "fetch")
    Term.(
      const run $ setup $ org_term $ project_goals_term $ project_number_term
      $ okr_updates_dir_term $ admin_dir_term $ data_dir_term $ years $ weeks
      $ users $ ids $ dry_run_term $ source_term Github $ items_per_page)

let default =
  let run () format org goals project_numbers okr_updates_dir admin_dir data_dir
      timesheets heatmap years weeks users ids source dry_run all items_per_page
      =
    Lwt_main.run
    @@
    if timesheets || heatmap then (
      let ts =
        get_timesheets ~years ~weeks ~users ~ids ~admin_dir ~okr_updates_dir
          ~data_dir ~lint:false source
      in
      (if heatmap then
         let heatmap = Heatmap.of_report ts in
         out_heatmap ~format heatmap);
      if timesheets then out_timesheets ts;
      Lwt.return ())
    else
      let+ project =
        get_project ?items_per_page org goals project_numbers data_dir dry_run
          source
      in
      let data =
        if all then { org; project }
        else
          let filter_out =
            match ids with
            | None -> None
            | Some ids -> Some (List.map (fun id -> (Column.Id, id)) ids)
          in
          let () =
            match users with
            | None -> ()
            | Some _ -> Fmt.epr "warning: ignoring filter --users\n%!"
          in
          filter ?filter_out { org; project }
      in
      out ~format data
  in
  Term.(
    const run $ setup $ format $ org_term $ project_goals_term
    $ project_number_term $ okr_updates_dir_term $ admin_dir_term
    $ data_dir_term $ timesheets_term $ heatmap_term $ years $ weeks $ users
    $ ids $ source_term Local $ dry_run_term $ all $ items_per_page)

let show = Cmd.v (Cmd.info "show") default

let sync =
  let run () org goals project_numbers okr_updates_dir admin_dir data_dir years
      weeks users ids dry_run source items_per_page =
    Lwt_main.run
    @@ let* project =
         get_project ?items_per_page org goals project_numbers data_dir dry_run
           source
       in
       let timesheets =
         get_timesheets ~years ~weeks ~users ~ids ~okr_updates_dir ~data_dir
           ~admin_dir ~lint:false source
       in
       let heatmap = Heatmap.of_report timesheets in
       let filter_out =
         [ (Column.Id, Filter.is "New KR"); (Id, Filter.is "") ]
       in
       let data = filter ~filter_out { org; project } in
       Project.sync ~heatmap data.project
  in
  Cmd.v (Cmd.info "sync")
    Term.(
      const run $ setup $ org_term $ project_goals_term $ project_number_term
      $ okr_updates_dir_term $ admin_dir_term $ data_dir_term $ years $ weeks
      $ users $ ids $ dry_run_term $ source_term Local $ items_per_page)

let lint =
  let run () org goals project_numbers okr_updates_dir admin_dir data_dir years
      weeks users ids dry_run source items_per_page =
    Lwt_main.run
    @@ let+ project =
         get_project ?items_per_page org goals project_numbers data_dir dry_run
           source
       in
       let timesheets =
         get_timesheets ~years ~weeks ~users ~ids ~okr_updates_dir ~data_dir
           ~lint:true ~admin_dir source
       in
       let heatmap = Heatmap.of_report timesheets in
       lint_project ~heatmap { org; project }
  in
  Cmd.v (Cmd.info "lint")
    Term.(
      const run $ setup $ org_term $ project_goals_term $ project_number_term
      $ okr_updates_dir_term $ admin_dir_term $ data_dir_term $ years $ weeks
      $ users $ ids $ dry_run_term $ source_term Local $ items_per_page)

let cmd = Cmd.group ~default (Cmd.info "caretaker") [ show; lint; sync; fetch ]

let () =
  let () = Printexc.record_backtrace true in
  match Cmd.eval ~catch:false cmd with
  | i -> exit i
  | exception Invalid_argument s ->
      Fmt.epr "\n%a %s\n%!" Fmt.(styled `Red string) "[ERROR]" s;
      exit Cmd.Exit.cli_error
  | exception e ->
      Printexc.print_backtrace stderr;
      Fmt.epr "\n%a\n%!" Fmt.exn e;
      exit Cmd.Exit.some_error
