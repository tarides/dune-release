open Cmdliner
open Dune_release

let run var =
  let open Rresult in
  let pkg = Pkg.v ~dry_run:false () in
  let result =
    match var with
    | "tarball" ->
        Pkg.distrib_file ~dry_run:false pkg >>| fun distrib_file ->
        Format.printf "%a\n" Fpath.pp distrib_file
    | "docdir" -> Ok (Format.printf "%a\n" Fpath.pp Pkg.doc_dir)
    | "publication-message" ->
        Pkg.publish_msg pkg >>| fun msg -> Format.printf "%s\n" msg
    | _ -> Rresult.R.error_msgf "Unknown variable %S" var
  in
  match result with
  | Ok _ -> 0
  | Error (`Msg msg) ->
      App_log.unhappy (fun m -> m "%s" msg);
      1

let var =
  let doc = "The variable to print." in
  Arg.(required & pos 0 (some string) None & info [] ~doc ~docv:"VAR")

let term = Term.(pure run $ var)

let info =
  Term.info "delegate-info" ~doc:"Prints out the given variable to stdout"

let cmd = (term, info)
