open Caretaker
open Common
open Lwt.Syntax
module U = Yojson.Safe.Util

type t = { org : string; project : Project.t }

let pp ppf t =
  Fmt.pf ppf "org: %s\n" t.org;
  Project.pp ppf t.project

let pp_csv headers ppf t = Fmt.string ppf (Project.to_csv ~headers t.project)
let pp_csv_ts ppf t = Fmt.string ppf (Report.to_csv t)

let filter ?filter_out data =
  let filter = Project.filter ?filter_out in
  { data with project = filter data.project }

type format = { style : [ `Plain | `CSV ]; fields : Column.t list }

let out ~format t =
  match format.style with
  | `Plain -> Fmt.pr "%a\n%!" pp t
  | `CSV -> Fmt.pr "%a%!" (pp_csv format.fields) t

let out_timesheets t = Fmt.pr "%a%!" pp_csv_ts t

let out_heatmap ~format t =
  match format.style with
  | `Plain -> Fmt.pr "%a\n%!" Heatmap.pp t
  | `CSV -> Fmt.pr "%s%!" (Heatmap.to_csv t)

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

let default =
  let run () format org goals project_number okr_updates_dir admin_dir data_dir
      timesheets heatmap years weeks users ids source dry_run all items_per_page
      =
    Lwt_main.run
    @@
    if timesheets || heatmap then (
      let ts =
        Fs.get_timesheets ~years ~weeks ~users ~ids ~admin_dir ~okr_updates_dir
          ~data_dir ~lint:false source
      in
      (if heatmap then
         let heatmap = Heatmap.of_report ts in
         out_heatmap ~format heatmap);
      if timesheets then out_timesheets ts;
      Lwt.return ())
    else
      let+ project =
        Fs.get_project ?items_per_page ~org ~goals ~project_number ~data_dir
          ~dry_run source
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

let cmd =
  Cmd.group ~default (Cmd.info "caretaker")
    [ show; Lint.cmd; Sync.cmd; Fetch.cmd ]

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
