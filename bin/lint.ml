open Cmdliner
open Lwt.Syntax
open Caretaker

let run t =
  Lwt_main.run
  @@ let+ project = Fs.get_project t in
     let timesheets = Fs.get_timesheets ~lint:true t in
     let heatmap = Heatmap.of_report timesheets in
     Project.lint ~heatmap project

let cmd =
  Cmd.v (Cmd.info "lint") Term.(const run $ Common.term ~default_source:Local)
