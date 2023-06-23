open Caretaker
open Lwt.Syntax
module U = Yojson.Safe.Util

let ( / ) = Filename.concat

type t = { org : string; projects : Project.t list }

let pp ppf t =
  Fmt.pf ppf "org: %s\n" t.org;
  List.iter (Project.pp ppf) t.projects

let pp_csv ppf t =
  List.iter (fun p -> Fmt.string ppf (Project.to_csv p)) t.projects

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

let read_timesheets ~years ~weeks okr_updates_dir =
  List.fold_left
    (fun acc year ->
      let root = okr_updates_dir / "team-weeklies" / string_of_int year in
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
                let str = read_file (dir / file) in
                Report.of_markdown ~acc ~year ~week str)
              acc files)
        acc weeks)
    (Hashtbl.create 13) years

let filter ?filter_out data =
  let filter = Project.filter ?filter_out in
  { data with projects = List.map filter data.projects }

let out ~format t =
  match format with
  | `Plain -> Fmt.pr "%a\n%!" pp t
  | `CSV -> Fmt.pr "%a\n%!" pp_csv t

let write ~dir t =
  List.iter
    (fun p ->
      (* save what is needed to update offline *)
      let file =
        dir / Fmt.str "%s-%d.json" (Project.org p) (Project.number p)
      in
      let json = Project.to_json p in
      let data = Yojson.Safe.to_string ~std:true json in
      write_file file data)
    t.projects;
  (* save what is needed to sync with dashboard *)
  let file = dir / "projects.csv" in
  let data = Fmt.str "%a\n" pp_csv t in
  write_file file data

let lint_project ?heatmap ~db t =
  List.iter (Project.lint ?heatmap ~db) t.projects

let out_timesheets t = Fmt.pr "%a\n%!" pp_csv_ts t

let write_timesheets ~dir t =
  let file = dir / "timesheets.csv" in
  let data = Fmt.str "%a\n" pp_csv_ts t in
  write_file file data

open Cmdliner

let org_term =
  Arg.(
    value @@ pos 0 string "tarides"
    @@ info ~doc:"The organisation to get projects from" ~docv:"ORG" [])

let project_numbers_term =
  Arg.(
    value
    @@ opt (list int) [ 25 ]
    @@ info ~doc:"The project IDS" ~docv:"IDs" [ "number"; "n" ])

let data_dir_term =
  let env = Cmd.Env.info ~doc:"PATH" "CARETAKER_DATA_DIR" in
  Arg.(
    value @@ opt string "data"
    @@ info ~env
         ~doc:"Use data from a local directory instead of querying the web"
         ~docv:"FILE" [ "d"; "data-dir" ])

let data_dir_opt =
  let env = Cmd.Env.info ~doc:"PATH" "CARETAKER_DATA_DIR" in
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

let timesheets_term =
  Arg.(
    value @@ flag @@ info ~doc:"Display timesheet reports" [ "timesheets"; "t" ])

let setup =
  let style_renderer = Fmt_cli.style_renderer ~docs:common_options () in
  Term.(
    const (fun style_renderer -> Fmt_tty.setup_std_outputs ?style_renderer ())
    $ style_renderer)

let all_weeks = List.init 52 (fun i -> i + 1)
let all_years = [ 2021; 2022; 2023 ]
let filter_sync = [ (Column.Id, Filter.is "New KR"); (Id, Filter.is "") ]

let err_okr_updates_dir () =
  failwith
    "Please set-up OKR_UPDATES_DIR to point to your local copy of the \
     okr-updates repositories"

let get_okr_updates_dir = function
  | None -> err_okr_updates_dir ()
  | Some dir -> dir

let get_timesheets ?(years = all_years) ?(weeks = all_weeks) ~data_dir
    ~okr_updates_dir () =
  match data_dir with
  | None ->
      let okr_updates_dir = get_okr_updates_dir okr_updates_dir in
      read_timesheets ~years ~weeks okr_updates_dir
  | Some dir ->
      let file = dir / "timesheets.csv" in
      let data = read_file file in
      Report.of_csv data

let get_project org project_numbers data_dir =
  match data_dir with
  | None -> Project.get_all ~org project_numbers
  | Some dir ->
      List.map
        (fun n ->
          let file = dir / Fmt.str "%s-%d.json" org n in
          if not (Sys.file_exists file) then
            failwith "Run `caretaker fetch' first";
          let data = read_file file in
          let json = Yojson.Safe.from_string data in
          Project.of_json json)
        project_numbers
      |> Lwt.return

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
  let run () org project_numbers okr_updates_dir data_dir =
    Lwt_main.run
    @@
    let dir = get_okr_updates_dir okr_updates_dir in
    let timesheets =
      get_timesheets ~okr_updates_dir:(Some dir) ~data_dir:None ()
    in
    let+ projects = Project.get_all ~org project_numbers in
    write_timesheets ~dir:data_dir timesheets;
    write ~dir:data_dir { org; projects };
    copy_db ~src:dir ~dst:data_dir
  in
  Cmd.v (Cmd.info "fetch")
    Term.(
      const run $ setup $ org_term $ project_numbers_term $ okr_updates_dir_term
      $ data_dir_term)

let default =
  let run () format org project_numbers okr_updates_dir timesheets data_dir =
    Lwt_main.run
    @@
    if timesheets then (
      let timesheets = get_timesheets ~okr_updates_dir ~data_dir () in
      out_timesheets timesheets;
      Lwt.return ())
    else
      let+ projects = get_project org project_numbers data_dir in
      let data = filter { org; projects } in
      out ~format data
  in
  Term.(
    const run $ setup $ format $ org_term $ project_numbers_term
    $ okr_updates_dir_term $ timesheets_term $ data_dir_opt)

let show = Cmd.v (Cmd.info "show") default

let sync =
  let run () org project_numbers okr_updates_dir data_dir =
    Lwt_main.run
    @@ let* projects = get_project org project_numbers data_dir in
       let timesheets = get_timesheets ~okr_updates_dir ~data_dir () in
       let db = get_db ~okr_updates_dir ~data_dir () in
       let heatmap = Heatmap.of_report timesheets in
       let data = filter ~filter_out:filter_sync { org; projects } in
       Lwt_list.iter_p (Project.sync ~db ~heatmap) data.projects
  in
  Cmd.v (Cmd.info "sync")
    Term.(
      const run $ setup $ org_term $ project_numbers_term $ okr_updates_dir_term
      $ data_dir_opt)

let lint =
  let run () org project_numbers okr_updates_dir data_dir =
    Lwt_main.run
    @@ let+ projects = get_project org project_numbers data_dir in
       let db = get_db ~okr_updates_dir ~data_dir () in
       let timesheets = get_timesheets ~okr_updates_dir ~data_dir () in
       let heatmap = Heatmap.of_report timesheets in
       let data = filter { org; projects } in
       lint_project ~heatmap ~db data
  in
  Cmd.v (Cmd.info "lint")
    Term.(
      const run $ setup $ org_term $ project_numbers_term $ okr_updates_dir_term
      $ data_dir_opt)

let cmd = Cmd.group ~default (Cmd.info "caretaker") [ show; lint; sync; fetch ]
let () = exit (Cmd.eval cmd)
