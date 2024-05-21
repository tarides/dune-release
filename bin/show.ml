open Cmdliner
open Lwt.Syntax
open Common
open Caretaker

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

let run format timesheets heatmap all ({ org; ids; users; _ } as t) =
  Lwt_main.run
  @@
  if timesheets || heatmap then (
    let ts = Fs.get_timesheets ~lint:false t in
    (if heatmap then
       let heatmap = Heatmap.of_report ts in
       out_heatmap ~format heatmap);
    if timesheets then out_timesheets ts;
    Lwt.return ())
  else
    let+ project = Fs.get_project t in
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

let term =
  Term.(
    const run $ format $ timesheets_term $ heatmap_term $ all
    $ Common.term ~default_source:Local)

let cmd = Cmd.v (Cmd.info "show") term
