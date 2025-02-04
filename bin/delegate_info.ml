open Cmdliner
open Dune_release

let term =
  Term.(
    let open Syntax in
    let+ var =
      let doc = "The variable to print." in
      Arg.(required & pos 0 (some string) None & info [] ~doc ~docv:"VAR")
    in
    let open Rresult in
    (let pkg = Pkg.v ~dry_run:false () in
     let result =
       match var with
       | "tarball" ->
           Pkg.distrib_archive_path pkg >>| fun distrib_file ->
           Format.printf "%a\n" Fpath.pp distrib_file
       | "docdir" -> Ok (Format.printf "%a\n" Fpath.pp Pkg.doc_dir)
       | "version" ->
           Pkg.version pkg >>| fun v -> Format.printf "%a\n%!" Version.pp v
       | "publication-message" ->
           Pkg.publish_msg pkg >>| fun msg -> Format.printf "%s\n" msg
       | _ -> Rresult.R.error_msgf "Unknown variable %S" var
     in
     result >>= fun () -> Ok 0)
    |> Cli.handle_error)

let info =
  Cmd.info "delegate-info" ~doc:"Prints out the given variable to stdout"

let cmd = Cmd.v info term
