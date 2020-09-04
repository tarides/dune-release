open Bos_setup
open Dune_release

let undraft ?build_dir ?opam ~name ~dry_run ~yes () =
  App_log.status (fun l -> l "Undrafting release");
  App_log.status (fun l -> l "Undrafting pull request");
  ignore build_dir;
  ignore opam;
  ignore name;
  ignore dry_run;
  ignore yes;
  Ok 0

let undraft_cli () (`Build_dir build_dir) (`Dist_name name) (`Dist_opam opam)
    (`Dry_run dry_run) (`Yes yes) =
  undraft ?build_dir ?opam ~name ~dry_run ~yes () |> Cli.handle_error

(* Command line interface *)

open Cmdliner

let doc = "Publish package distribution archives and derived artefacts"

let sdocs = Manpage.s_common_options

let exits = Cli.exits

let envs =
  [
    Term.env_info "DUNE_RELEASE_DELEGATE"
      ~doc:"The package delegate to use, see dune-release-delegate(7).";
  ]

let man_xrefs = [ `Main; `Cmd "publish"; `Cmd "opam" ]

let man =
  [
    `S Manpage.s_synopsis;
    `P "$(mname) $(tname) [$(i,OPTION)]... [$(i,ARTEFACT)]...";
    `S Manpage.s_description;
    `P
      "The $(tname) command undrafts the released asset, updates the \
       opam-repository pull request and undrafts it.";
    `P
      "Undrafting a released asset always relies on a release having been \
       published before with dune-release-publish(1).";
    `P
      "Undrafting a pull request always relies on a pull request having been \
       opened before with dune-release-opam(2).";
  ]

let cmd =
  ( Term.(
      pure undraft_cli $ Cli.setup $ Cli.build_dir $ Cli.dist_name
      $ Cli.dist_opam $ Cli.dry_run $ Cli.yes),
    Term.info "undraft" ~doc ~sdocs ~exits ~envs ~man ~man_xrefs )
