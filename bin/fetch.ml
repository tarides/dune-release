open Cmdliner
open Lwt.Syntax
open Common
open Caretaker

let ( / ) = Filename.concat
let pp_csv_ts ppf t = Fmt.string ppf (Report.to_csv t)

let write_timesheets ~dir t =
  let file = dir / "timesheets.csv" in
  let data = Fmt.str "%a" pp_csv_ts t in
  Fs.write_file file data

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
          Fs.get_timesheets ~years ~weeks ~users ~ids ~admin_dir
            ~okr_updates_dir ~data_dir ~lint:false source
        in
        write_timesheets ~dir:data_dir report
  in
  let+ () =
    (* fetch project boards *)
    match (source, dry_run) with
    | Github, true ->
        let project = Project.empty org project_number in
        Fs.write ~dir:data_dir project;
        Lwt.return ()
    | Github, false ->
        let* goals = Fs.get_goals ~org ~repo:goals in
        let+ project =
          Project.get ~goals ~org ~project_number ?items_per_page ()
        in
        Fmt.epr "Found %d cards in %s/%d.\n%!"
          (List.length (Project.cards project))
          org project_number;
        Fs.write ~dir:data_dir project
    | _ -> Lwt.return ()
  in
  ()

let cmd =
  Cmd.v (Cmd.info "fetch")
    Term.(
      const run $ setup $ org_term $ project_goals_term $ project_number_term
      $ okr_updates_dir_term $ admin_dir_term $ data_dir_term $ years $ weeks
      $ users $ ids $ dry_run_term $ source_term Github $ items_per_page)
