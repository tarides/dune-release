open Caretaker
open Lwt.Syntax
module U = Yojson.Safe.Util

let ( / ) = Filename.concat

type t = { org : string; project : Project.t }

let pp ppf t =
  Fmt.pf ppf "org: %s\n" t.org;
  Project.pp ppf t.project

let pp_csv ppf t = Fmt.string ppf (Project.to_csv t.project)
let pp_csv_ts ppf t = Fmt.string ppf (Report.to_csv t)

let read_file f =
  let ic = open_in f in
  let s = really_input_string ic (in_channel_length ic) in
  close_in ic;
  s

let write_file f data =
  Fmt.pr "Writing %s\n%!" f;
  let oc = open_out f in
  let s = output_string oc data in
  close_out oc;
  s

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
                Report.of_markdown ~lint ~acc ~path ~year ~week ~users ~ids str)
              acc files)
        acc weeks)
    (Hashtbl.create 13) years

let read_timesheets_from_okr_updates d = read_timesheets (d / "team-weeklies")
let read_timesheets_from_admin d = read_timesheets (d / "weekly")

let filter ?filter_out data =
  let filter = Project.filter ?filter_out in
  { data with project = filter data.project }

let out ~format t =
  match format with
  | `Plain -> Fmt.pr "%a\n%!" pp t
  | `CSV -> Fmt.pr "%a%!" pp_csv t

let write ~dir t =
  (* save what is needed to update offline *)
  let file =
    dir
    / Fmt.str "%s-%d.json" (Project.org t.project) (Project.number t.project)
  in
  let json = Project.to_json t.project in
  let data = Yojson.Safe.to_string ~std:true json in
  write_file file data;
  (* save what is needed to sync with dashboard *)
  let file = dir / "projects.csv" in
  let data = Fmt.str "%a\n" pp_csv t in
  write_file file data

let lint_project ?heatmap ~db t = Project.lint ?heatmap ~db t.project
let out_timesheets t = Fmt.pr "%a\n%!" pp_csv_ts t
let out_heatmap t = Fmt.pr "%a\n%!" Heatmap.pp t

let write_timesheets ~dir t =
  let file = dir / "timesheets.csv" in
  let data = Fmt.str "%a\n" pp_csv_ts t in
  write_file file data

open Cmdliner

let all =
  let doc =
    Arg.info ~doc:"Show all items (by default, just show open cards and issues"
      [ "all" ]
  in
  Arg.(value @@ flag doc)

let org_term =
  Arg.(
    value @@ pos 0 string "tarides"
    @@ info ~doc:"The organisation to get projects from" ~docv:"ORG" [])

type source = Sync | Okr_updates | Admin

let source_term =
  let sources =
    Arg.enum [ ("sync", Sync); ("okr-updates", Okr_updates); ("admin", Admin) ]
  in
  Arg.(
    value @@ opt sources Sync
    @@ info ~doc:"The data-source to read data from." ~docv:"SOURCE"
         [ "source"; "s" ])

let project_number_term =
  Arg.(
    value @@ opt int 25
    @@ info ~doc:"The project IDS" ~docv:"ID" [ "number"; "n" ])

let project_goals_term =
  Arg.(
    value @@ opt string "goals"
    @@ info ~doc:"The project goals" ~docv:"REPOSITORY" [ "goals" ])

let years =
  let all_years = [ 2021; 2022; 2023 ] in
  Arg.(
    value
    @@ opt (list ~sep:',' int) all_years
    @@ info ~doc:"The years to consider" ~docv:"YEARS" [ "years" ])

let weeks =
  let weeks = Arg.conv (Weeks.of_string, Weeks.pp) in
  Arg.(
    value @@ opt weeks Weeks.all
    @@ info
         ~doc:
           "The weeks to consider. By default, use all weeks. The format is a \
            $(b,`,')-separated list of values, where a value is either \
            specific week number, an (inclusive) range between week numbers \
            like $(b,`12-16'), or a quarter name (like $(b,`q1'). For \
            instance, $(b,--weeks='12,q1,34-45') is a valid parameter."
         ~docv:"WEEKS" [ "weeks" ])

let users =
  Arg.(
    value
    @@ opt (some (list ~sep:',' string)) None
    @@ info ~doc:"The users to consider" ~docv:"NAMES" [ "users" ])

let ids =
  let arg =
    Arg.(
      value
      @@ opt (some (list ~sep:',' string)) None
      @@ info
           ~doc:
             "The IDs to consider. Use $(b, -id) to not consider a specific ID \
              $(b,id). "
           ~docv:"IDs" [ "ids" ])
  in
  let f ids =
    match ids with
    | None -> None
    | Some ids ->
        Some
          (List.map
             (fun id ->
               if String.starts_with ~prefix:"-" id then
                 Filter.is_not (String.sub id 1 (String.length id - 1))
               else Filter.is id)
             ids)
  in
  Term.(const f $ arg)

let data_dir_term =
  let env = Cmd.Env.info ~doc:"PATH" "DATA_DIR" in
  Arg.(
    value
    @@ opt (some string) None
    @@ info ~env
         ~doc:"Use data from a local directory instead of querying the web"
         ~docv:"FILE" [ "d"; "data-dir" ])

let format =
  Arg.(
    value
    @@ opt (enum [ ("plain", `Plain); ("csv", `CSV) ]) `Plain
    @@ info ~doc:"The output format" [ "format"; "f" ])

let common_options = "COMMON OPTIONS"

let okr_updates_dir_term =
  let env = Cmd.Env.info ~doc:"PATH" "OKR_UPDATES_DIR" in
  Arg.(
    value
    @@ opt (some string) None
    @@ info ~docs:common_options ~env ~doc:"Path to the okr-updates repository"
         [ "okr-updates-dir" ])

let admin_dir_term =
  let env = Cmd.Env.info ~doc:"PATH" "ADMIN_DIR" in
  Arg.(
    value
    @@ opt (some string) None
    @@ info ~docs:common_options ~env ~doc:"Path to the admin repository"
         [ "admin-dir" ])

let timesheets_term =
  Arg.(value @@ flag @@ info ~doc:"Display timesheet reports" [ "timesheets" ])

let heatmap_term =
  Arg.(value @@ flag @@ info ~doc:"Display heatmap reports" [ "heatmap" ])

let setup =
  let style_renderer = Fmt_cli.style_renderer ~docs:common_options () in
  Term.(
    const (fun style_renderer level ->
        Fmt_tty.setup_std_outputs ?style_renderer ();
        Logs.set_level level;
        Logs.set_reporter (Logs_fmt.reporter ()))
    $ style_renderer $ Logs_cli.level ())

let err_okr_updates_dir () =
  invalid_arg
    "Missing path to tarides/okr-updates. Please use --okr-updates-dir \n\
     or set-up OKR_UPDATES_DIR to point to your local copy of the \n\
     tarides/okr-updates repositories."

let err_data_dir () =
  invalid_arg
    "Missing path to local synced data. Please use --data-dir or set-up \n\
     DATA_DIR to point to your local copy of the local synced data."

let err_admin_dir () =
  invalid_arg
    "Missing path to tarides/admin. Please use --admin-dir or set-up ADMIN_DIR \n\
     to point to your local copy of the local tarides/admin repositories."

let get_okr_updates_dir = function
  | None -> err_okr_updates_dir ()
  | Some dir -> dir

let get_admin_dir = function None -> err_admin_dir () | Some dir -> dir
let get_data_dir = function None -> err_data_dir () | Some dir -> dir

let get_timesheets ~years ~weeks ~users ~ids ~lint ~data_dir ~okr_updates_dir
    ~admin_dir = function
  | Sync ->
      let dir = get_data_dir data_dir in
      let file = dir / "timesheets.csv" in
      let data = read_file file in
      Report.of_csv ~years ~weeks ~users ~ids data
  | Okr_updates ->
      let dir = get_okr_updates_dir okr_updates_dir in
      read_timesheets_from_okr_updates ~years ~weeks ~users ~ids ~lint dir
  | Admin ->
      let dir = get_admin_dir admin_dir in
      read_timesheets_from_admin ~years ~weeks ~users ~ids ~lint dir

let get_goals org repo =
  let+ issues = Issue.list ~org ~repo () in
  Fmt.pr "Found %d goals in %s/%s.\n%!" (List.length issues) org repo;
  issues

let get_project org goals project_number data_dir =
  match data_dir with
  | None ->
      let* goals = get_goals org goals in
      let+ project = Project.get ~org ~project_number ~goals () in
      Fmt.epr "Found %d cards in %s/%d.\n%!"
        (List.length (Project.cards project))
        org project_number;
      project
  | Some dir ->
      let file = dir / Fmt.str "%s-%d.json" org project_number in
      if not (Sys.file_exists file) then failwith "Run `caretaker fetch' first";
      let data = read_file file in
      let json = Yojson.Safe.from_string data in
      Lwt.return (Project.of_json json)

let get_db ~okr_updates_dir ~data_dir () =
  let file =
    match data_dir with
    | None ->
        let dir = get_okr_updates_dir okr_updates_dir in
        dir / "team-weeklies" / "db.csv"
    | Some dir -> dir / "db.csv"
  in
  Okra.Masterdb.load_csv file

let copy_db ~src ~dst =
  (* FIXME: no Okra.Masterdb.write_csv *)
  Fmt.pr "Writing %s/db.csv\n" dst;
  let x : int = Fmt.kstr Sys.command "cp %s/team-weeklies/db.csv %s/" src dst in
  if x <> 0 then failwith "invalid cp"

let fetch =
  let run () org goals project_number okr_updates_dir admin_dir data_dir years
      weeks users ids source =
    Lwt_main.run
    @@
    let data_dir = get_data_dir data_dir in
    let timesheets =
      get_timesheets ~years ~weeks ~users ~ids ~admin_dir ~okr_updates_dir
        ~data_dir:None ~lint:false
        (if source = Sync then Okr_updates else source)
    in
    let* goals = get_goals org goals in
    let+ project = Project.get ~goals ~org ~project_number () in
    Fmt.epr "Found %d cards in %s/%d.\n%!"
      (List.length (Project.cards project))
      org project_number;
    write_timesheets ~dir:data_dir timesheets;
    write ~dir:data_dir { org; project };
    let dir = get_okr_updates_dir okr_updates_dir in
    copy_db ~src:dir ~dst:data_dir
  in
  Cmd.v (Cmd.info "fetch")
    Term.(
      const run $ setup $ org_term $ project_goals_term $ project_number_term
      $ okr_updates_dir_term $ admin_dir_term $ data_dir_term $ years $ weeks
      $ users $ ids $ source_term)

let default =
  let run () format org goals project_numbers okr_updates_dir admin_dir data_dir
      timesheets heatmap years weeks users ids sources all =
    Lwt_main.run
    @@
    if timesheets || heatmap then (
      let ts =
        get_timesheets ~years ~weeks ~users ~ids ~admin_dir ~okr_updates_dir
          ~data_dir ~lint:false sources
      in
      (if heatmap then
         let heatmap = Heatmap.of_report ts in
         out_heatmap heatmap);
      if timesheets then out_timesheets ts;
      Lwt.return ())
    else
      let+ project = get_project org goals project_numbers data_dir in
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
    $ ids $ source_term $ all)

let show = Cmd.v (Cmd.info "show") default

let sync =
  let run () org goals project_numbers okr_updates_dir admin_dir data_dir years
      weeks users ids sources =
    Lwt_main.run
    @@ let* project = get_project org goals project_numbers data_dir in
       let timesheets =
         get_timesheets ~years ~weeks ~users ~ids ~okr_updates_dir ~data_dir
           ~admin_dir ~lint:false sources
       in
       let db = get_db ~okr_updates_dir ~data_dir () in
       let heatmap = Heatmap.of_report timesheets in
       let filter_out =
         [ (Column.Id, Filter.is "New KR"); (Id, Filter.is "") ]
       in
       let data = filter ~filter_out { org; project } in
       Project.sync ~db ~heatmap data.project
  in
  Cmd.v (Cmd.info "sync")
    Term.(
      const run $ setup $ org_term $ project_goals_term $ project_number_term
      $ okr_updates_dir_term $ admin_dir_term $ data_dir_term $ years $ weeks
      $ users $ ids $ source_term)

let lint =
  let run () org goals project_numbers okr_updates_dir admin_dir data_dir years
      weeks users ids sources =
    Lwt_main.run
    @@ let+ project = get_project org goals project_numbers data_dir in
       let db = get_db ~okr_updates_dir ~data_dir () in
       let timesheets =
         get_timesheets ~years ~weeks ~users ~ids ~okr_updates_dir ~data_dir
           ~lint:true ~admin_dir sources
       in
       let heatmap = Heatmap.of_report timesheets in
       lint_project ~heatmap ~db { org; project }
  in
  Cmd.v (Cmd.info "lint")
    Term.(
      const run $ setup $ org_term $ project_goals_term $ project_number_term
      $ okr_updates_dir_term $ admin_dir_term $ data_dir_term $ years $ weeks
      $ users $ ids $ source_term)

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
