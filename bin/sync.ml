open Cmdliner
open Lwt.Syntax
open Common
open Caretaker

let run () org goals project_number okr_updates_dir admin_dir data_dir years
    weeks users ids dry_run source items_per_page =
  Lwt_main.run
  @@ let* project =
       Fs.get_project ?items_per_page ~org ~goals ~project_number ~data_dir
         ~dry_run source
     in
     let timesheets =
       Fs.get_timesheets ~years ~weeks ~users ~ids ~okr_updates_dir ~data_dir
         ~admin_dir ~lint:false source
     in
     let heatmap = Heatmap.of_report timesheets in
     let filter_out = [ (Column.Id, Filter.is "New KR"); (Id, Filter.is "") ] in
     let project = Project.filter ~filter_out project in
     Project.sync ~heatmap project

let cmd =
  Cmd.v (Cmd.info "sync")
    Term.(
      const run $ setup $ org_term $ project_goals_term $ project_number_term
      $ okr_updates_dir_term $ admin_dir_term $ data_dir_term $ years $ weeks
      $ users $ ids $ dry_run_term $ source_term Local $ items_per_page)
