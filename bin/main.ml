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

let lint_project ?heatmap ~db t =
  List.iter (Project.lint ?heatmap ~db) t.projects

let out_timesheets t = Fmt.pr "%a\n%!" pp_csv_ts t

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

let get_timesheets ?(years = all_years) ?(weeks = all_weeks) dir =
  read_timesheets ~years ~weeks dir

let get_db dir = Okra.Masterdb.load_csv (dir / "team-weeklies" / "db.csv")

let default =
  let run () format org project_numbers okr_updates_dir timesheets =
    Lwt_main.run
    @@
    if timesheets then (
      let dir = get_okr_updates_dir okr_updates_dir in
      let timesheets = get_timesheets dir in
      out_timesheets timesheets;
      Lwt.return ())
    else
      let+ projects = Project.get_all ~org_name:org project_numbers in
      let data = filter { org; projects } in
      out ~format data
  in
  Term.(
    const run $ setup $ format $ org_term $ project_numbers_term
    $ okr_updates_dir_term $ timesheets_term)

let show = Cmd.v (Cmd.info "show") default

let sync =
  let run () org project_numbers okr_updates_dir =
    Lwt_main.run
    @@ let* projects = Project.get_all ~org_name:org project_numbers in
       let dir = get_okr_updates_dir okr_updates_dir in
       let db = get_db dir in
       let timesheets = get_timesheets dir in
       let heatmap = Heatmap.of_report timesheets in
       let data = filter ~filter_out:filter_sync { org; projects } in
       Lwt_list.iter_p (Project.sync ~db ~heatmap) data.projects
  in
  Cmd.v (Cmd.info "sync")
    Term.(
      const run $ setup $ org_term $ project_numbers_term $ okr_updates_dir_term)

let lint =
  let run () org project_numbers okr_updates_dir =
    Lwt_main.run
    @@ let+ projects = Project.get_all ~org_name:org project_numbers in
       let dir = get_okr_updates_dir okr_updates_dir in
       let db = get_db dir in
       let timesheets = get_timesheets dir in
       let heatmap = Heatmap.of_report timesheets in
       let data = filter { org; projects } in
       lint_project ~heatmap ~db data
  in
  Cmd.v (Cmd.info "sync")
    Term.(
      const run $ setup $ org_term $ project_numbers_term $ okr_updates_dir_term)

let cmd = Cmd.group ~default (Cmd.info "caretaker") [ show; lint; sync ]
let () = exit (Cmd.eval cmd)
