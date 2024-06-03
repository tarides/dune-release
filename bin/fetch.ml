open Cmdliner
open Lwt.Syntax
open Common
open Caretaker

let ( / ) = Filename.concat
let pp_csv_ts ppf t = Fmt.string ppf (Report.to_csv t)

let write_timesheets ~dir t =
  let file = dir / "timesheets.csv" in
  let data = Fmt.str "%a" pp_csv_ts t in
  IO.write_file file data

let run ({ Common.data_dir; source; okr_updates_dir; admin_dir; _ } as t) =
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
        let report = IO.get_timesheets ~lint:false t in
        write_timesheets ~dir:data_dir report
  in
  let+ () =
    (* fetch project boards *)
    match source with
    | Github ->
        let+ project = IO.get_project t in
        IO.write ~dir:data_dir project
    | _ -> Lwt.return ()
  in
  ()

let cmd =
  Cmd.v (Cmd.info "fetch") Term.(const run $ Common.term ~default_source:Github)
