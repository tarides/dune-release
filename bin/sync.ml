open Cmdliner
open Lwt.Syntax
open Common
open Caretaker

let run t =
  Lwt_main.run
  @@ let* project = IO.get_project t in
     let* timesheets = IO.get_timesheets ~lint:false t in
     let heatmap = Heatmap.of_report timesheets in
     let filter_out =
       [ (Column.Id, Filter.Query.is "New KR"); (Id, Filter.Query.is "") ]
     in
     let project = Project.filter ~filter_out project in
     Project.sync ~heatmap project

let cmd =
  Cmd.v (Cmd.info "sync") Term.(const run $ Common.term ~default_source:Local)
