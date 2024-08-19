open Cmdliner
open Lwt.Syntax
open Common
open Caretaker

let ( / ) = Filename.concat

let write_timesheets ~dir t =
  let file = dir / "timesheets.csv" in
  IO.with_out_file file (fun oc -> Report.to_csv oc t)

let fetch_timesheets ~dir t =
  match t.source with
  | Local | Github -> ()
  | Okr_updates | Admin ->
      let report = IO.get_timesheets ~lint:false t in
      write_timesheets ~dir report

let fetch_project_board ~dir t =
  match t.source with
  | Github ->
      let+ project = IO.get_project t in
      IO.write ~dir project
  | Local | Okr_updates | Admin -> Lwt.return ()

let run ({ Common.data_dir; source; okr_updates_dir; admin_dir; _ } as t) =
  Lwt_main.run
  @@
  let source =
    match (source, okr_updates_dir, admin_dir) with
    | Github, Some dir, _ ->
        Logs.debug (fun m -> m "Reading timesheets from `%s'." dir);
        Okr_updates
    | Github, _, Some dir ->
        Logs.debug (fun m -> m "Reading timesheets from `%s'." dir);
        Admin
    | (Github | Local), _, _ ->
        Logs.debug (fun m -> m "Skipping timesheets.");
        source
    | _ -> source
  in
  let () = fetch_timesheets ~dir:data_dir { t with source } in
  let+ () = fetch_project_board ~dir:data_dir t in
  ()

let cmd =
  Cmd.v (Cmd.info "fetch") Term.(const run $ Common.term ~default_source:Github)
