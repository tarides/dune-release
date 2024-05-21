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

let run
    ({
       Common.data_dir;
       items_per_page;
       dry_run;
       project_goals;
       org;
       project_number;
       source;
       okr_updates_dir;
       admin_dir;
       _;
     } as t) =
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
        let report = Fs.get_timesheets ~lint:false t in
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
        let* goals = Fs.get_goals ~org ~repo:project_goals in
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
  Cmd.v (Cmd.info "fetch") Term.(const run $ Common.term ~default_source:Github)
