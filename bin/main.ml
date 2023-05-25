open Caretaker
open Lwt.Syntax
module U = Yojson.Safe.Util

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
  let ( / ) = Filename.concat in
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

let out_ts t = Fmt.pr "%a\n%!" pp_csv_ts t

open Cmdliner

let org_term =
  Arg.(
    value @@ pos 0 string "tarides"
    @@ info ~doc:"The organisation to get projects from" ~docv:"ORG" [])

let project_numbers_term =
  Arg.(
    value
    @@ opt (list int) [ 5; 20 ]
    @@ info ~doc:"The project IDS" ~docv:"IDs" [ "number"; "n" ])

let format =
  Arg.(
    value
    @@ opt (enum [ ("plain", `Plain); ("csv", `CSV) ]) `Plain
    @@ info ~doc:"The output format" [ "format"; "f" ])

let okr_updates_dir_term =
  let env = Cmd.Env.info ~doc:"PATH" "OKR_UPDATES_DIR" in
  Arg.(
    value
    @@ opt (some string) None
    @@ info ~env ~doc:"Path to the okr-updates repository" [ "okr-updates-dir" ])

let timesheets_term =
  Arg.(value @@ flag @@ info ~doc:"Manage timesheets" [ "timesheets"; "t" ])

let setup =
  let style_renderer = Fmt_cli.style_renderer () in
  Term.(
    const (fun style_renderer -> Fmt_tty.setup_std_outputs ?style_renderer ())
    $ style_renderer)

let all_weeks = List.init 52 (fun i -> i + 1)
let all_years = [ 2022; 2023 ]

let projects () format org project_numbers okr_updates_dir timesheets =
  if timesheets then
    match okr_updates_dir with
    | None ->
        failwith
          "Please set-up OKR_UPDATES_DIR to point to your local copy of the \
           okr-updates repositories"
    | Some okr_updates_dir ->
        let ts =
          read_timesheets ~years:all_years ~weeks:all_weeks okr_updates_dir
        in
        out_ts ts
  else
    let lwt =
      let+ projects = Project.get_all ~org_name:org project_numbers in
      let data = filter { org; projects } in
      out ~format data
    in
    Lwt_main.run lwt

let cmd =
  Cmd.v (Cmd.info "gh-projects")
    Term.(
      const projects $ setup $ format $ org_term $ project_numbers_term
      $ okr_updates_dir_term $ timesheets_term)

let () = exit (Cmd.eval cmd)
