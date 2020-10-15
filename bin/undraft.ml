open Bos_setup
open Dune_release

let undraft ?opam ~name ?distrib_uri ?distrib_file ?opam_repo ?user ?token
    ?local_repo ?remote_repo ~dry_run ~yes:_ () =
  let pkg = Pkg.v ?name ?opam ?distrib_file ~dry_run:false () in
  let opam_repo =
    match opam_repo with None -> ("ocaml", "opam-repository") | Some r -> r
  in
  Config.v ~user ~local_repo ~remote_repo [ pkg ] >>= fun config ->
  ( match remote_repo with
  | Some r -> Ok r
  | None -> (
      match config.remote with
      | Some r -> Ok r
      | None -> R.error_msg "Unknown remote repository." ) )
  >>= fun remote_repo ->
  ( match distrib_uri with
  | Some uri -> Ok uri
  | None -> Pkg.infer_distrib_uri pkg )
  >>= Pkg.distrib_user_and_repo
  >>= fun (distrib_user, repo) ->
  let user =
    match config.user with
    | Some user -> user (* from the .yaml configuration file *)
    | None -> (
        match Github.Parse.user_from_remote remote_repo with
        | Some user -> user (* trying to infer it from the remote repo URI *)
        | None -> distrib_user )
  in
  (match token with Some t -> Ok t | None -> Config.token ~dry_run ())
  >>= fun token ->
  App_log.status (fun l -> l "Undrafting release");
  Sos.Draft_release.get ~dry_run >>= fun release_id ->
  Github.undraft_release ~token ~dry_run ~user ~repo ~release_id >>= fun url ->
  App_log.success (fun m ->
      m "The release has been undrafted and is available at %s\n" url);
  App_log.status (fun l -> l "Undrafting pull request");
  Sos.Draft_pr.get ~dry_run >>= fun pr_id ->
  Github.undraft_pr ~token ~dry_run ~distrib_user ~opam_repo ~pr_id
  >>= fun url ->
  Sos.Draft_release.unset ~dry_run >>= fun () ->
  Sos.Draft_pr.unset ~dry_run >>= fun () ->
  App_log.success (fun m -> m "The pull-request has been undrafted at %s\n" url);
  Ok 0

let undraft_cli () (`Dist_name name) (`Dist_uri distrib_uri) (`Dist_opam opam)
    (`Dist_file distrib_file) (`Opam_repo opam_repo) (`User user) (`Token token)
    (`Local_repo local_repo) (`Remote_repo remote_repo) (`Dry_run dry_run)
    (`Yes yes) =
  undraft ?opam ~name ?distrib_uri ?distrib_file ?opam_repo ?user ?token
    ?local_repo ?remote_repo ~dry_run ~yes ()
  |> Cli.handle_error

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

let opam_repo =
  let doc =
    "The Github opam-repository to which packages should be released. Use this \
     to release to a custom repo. Useful for testing purposes."
  in
  let docv = "GITHUB_USER_OR_ORG/REPO_NAME" in
  let env = Arg.env_var "DUNE_RELEASE_OPAM_REPO" in
  Cli.named
    (fun x -> `Opam_repo x)
    Arg.(
      value
      & opt (some (pair ~sep:'/' string string)) None
      & info ~env [ "opam-repo" ] ~doc ~docv)

let user =
  let doc =
    "the name of the GitHub account where to push new opam-repository branches."
  in
  Cli.named
    (fun x -> `User x)
    Arg.(
      value & opt (some string) None & info [ "u"; "user" ] ~doc ~docv:"USER")

let local_repo =
  let doc = "Location of the local fork of opam-repository" in
  let env = Arg.env_var "DUNE_RELEASE_LOCAL_REPO" in
  Cli.named
    (fun x -> `Local_repo x)
    Arg.(
      value
      & opt (some string) None
      & info ~env [ "l"; "--local-repo" ] ~doc ~docv:"PATH")

let remote_repo =
  let doc = "Location of the remote fork of opam-repository" in
  let env = Arg.env_var "DUNE_RELEASE_REMOTE_REPO" in
  Cli.named
    (fun x -> `Remote_repo x)
    Arg.(
      value
      & opt (some string) None
      & info ~env [ "r"; "--remote-repo" ] ~doc ~docv:"URI")

let cmd =
  ( Term.(
      pure undraft_cli $ Cli.setup $ Cli.dist_name $ Cli.dist_uri
      $ Cli.dist_opam $ Cli.dist_file $ opam_repo $ user $ Cli.token
      $ local_repo $ remote_repo $ Cli.dry_run $ Cli.yes),
    Term.info "undraft" ~doc ~sdocs ~exits ~envs ~man ~man_xrefs )
