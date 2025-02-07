open Bos_setup
open Dune_release

let get_pkg_dir pkg =
  Pkg.build_dir pkg >>= fun bdir ->
  Pkg.distrib_opam_path pkg >>= fun fname -> Ok Fpath.(bdir // fname)

let pp_opam_repo fmt opam_repo =
  let user, repo = opam_repo in
  Format.fprintf fmt "%s/%s" user repo

let update_opam_file ~dry_run ~url pkg =
  get_pkg_dir pkg >>= fun dir ->
  Pkg.opam pkg >>= fun opam_f ->
  OS.Dir.create dir >>= fun _ ->
  let dest_opam_file = Fpath.(dir / "opam") in
  let url = OpamUrl.parse url in
  let url = OpamFile.URL.create url in
  OS.File.read opam_f >>= fun opam ->
  let opam_t = OpamFile.OPAM.read_from_string opam in
  (match OpamVersion.to_string (OpamFile.OPAM.opam_version opam_t) with
  | "2.0" ->
      let file x = OpamFile.make (OpamFilename.of_string (Fpath.to_string x)) in
      let opam_t = OpamFile.OPAM.with_url url opam_t in
      if not dry_run then
        OpamFile.OPAM.write_with_preserved_format ~format_from:(file opam_f)
          (file dest_opam_file) opam_t;
      Ok ()
  | ("1.0" | "1.1" | "1.2") as v ->
      App_log.status (fun l ->
          l "Upgrading opam file %a from opam format %s to 2.0" Text.Pp.path
            opam_f v);
      let opam =
        OpamFile.OPAM.with_url url opam_t |> OpamFile.OPAM.write_to_string
      in
      Sos.write_file ~dry_run dest_opam_file opam
  | s -> Fmt.kstr (fun x -> Error (`Msg x)) "invalid opam version: %s" s)
  >>| fun () ->
  App_log.success (fun m ->
      m "Wrote opam package description %a" Text.Pp.path dest_opam_file)

let undraft ?opam ?distrib_file ?opam_repo ?token ?local_repo:local
    ?remote_repo:remote ?build_dir ?pkg_names ~dry_run ~yes:_ () =
  Config.token ~token ~dry_run () >>= fun token ->
  let pkg = Pkg.v ?opam ?distrib_file ?build_dir ~dry_run:false () in
  Config.opam_repo_fork ~pkgs:[ pkg ] ~user:None ~local ~remote ()
  >>= fun opam_repo_fork ->
  Pkg.name pkg >>= fun pkg_name ->
  Pkg.build_dir pkg >>= fun build_dir ->
  Pkg.version pkg >>= fun version ->
  Pkg.tag pkg >>= fun tag ->
  let pkg_names = match pkg_names with Some x -> x | None -> [] in
  let pkg_names = pkg_name :: pkg_names in
  let opam_repo =
    match opam_repo with None -> ("ocaml", "opam-repository") | Some r -> r
  in
  Pkg.infer_github_repo pkg >>= fun { owner; repo } ->
  Config.Draft_release.get ~dry_run ~build_dir ~name:pkg_name ~version
  >>= fun release_id ->
  App_log.status (fun l ->
      l "Undrafting release of package %a %a with id %s" Text.Pp.name pkg_name
        Text.Pp.version version release_id);
  Config.Release_asset_name.get ~dry_run ~build_dir ~name:pkg_name ~version
  >>= fun asset_name ->
  Github.undraft_release ~token ~dry_run ~owner ~repo ~release_id
    ~name:asset_name
  >>= fun url ->
  App_log.success (fun m ->
      m "The release #%s has been undrafted and is available at %s\n" release_id
        url);
  Config.Draft_pr.get ~dry_run ~build_dir ~name:pkg_name ~version
  >>= fun pr_id ->
  App_log.status (fun l ->
      l "Undrafting pull request of package %a %a with id %s" Text.Pp.name
        pkg_name Text.Pp.version version pr_id);
  update_opam_file ~dry_run ~url pkg >>= fun () ->
  App_log.status (fun l ->
      l "Preparing pull request #%s to %a" pr_id pp_opam_repo opam_repo);
  let branch = Fmt.str "release-%s-%a" pkg_name Vcs.Tag.pp tag in
  Vcs.get () >>= fun vcs ->
  let prepare_packages ~build_dir =
    Stdext.Result.List.iter
      ~f:(Opam.prepare_package ~build_dir ~dry_run ~version vcs)
  in
  let commit_and_push () =
    let msg = "Undraft pull-request" in
    Vcs.run_git_quiet vcs ~dry_run Cmd.(v "commit" % "-m" % msg) >>= fun () ->
    App_log.status (fun l ->
        l "Pushing %a to %a" Text.Pp.commit branch Text.Pp.url
          opam_repo_fork.remote);
    Vcs.run_git_quiet vcs ~dry_run
      Cmd.(v "push" % "--force" % opam_repo_fork.remote % branch)
  in
  OS.Dir.current () >>= fun cwd ->
  let build_dir = Fpath.(cwd / "_build") in
  Sos.with_dir ~dry_run opam_repo_fork.local
    (fun () ->
      let upstream =
        let user, repo = opam_repo in
        Printf.sprintf "https://github.com/%s/%s.git" user repo
      in
      let remote_branch = "master" in
      App_log.status (fun l ->
          l "Fetching %a" Text.Pp.url (upstream ^ "#" ^ remote_branch));
      Vcs.run_git_quiet vcs ~dry_run ~force:true
        Cmd.(v "fetch" % upstream % remote_branch)
      >>= fun () ->
      Vcs.change_branch vcs ~dry_run:false ~branch >>= fun () ->
      prepare_packages ~build_dir pkg_names >>= fun () -> commit_and_push ())
    ()
  |> R.join
  >>= fun () ->
  Github.undraft_pr ~token ~dry_run ~opam_repo ~pr_id >>= fun url ->
  Config.Draft_release.unset ~dry_run ~build_dir ~name:pkg_name ~version
  >>= fun () ->
  Config.Draft_pr.unset ~dry_run ~build_dir ~name:pkg_name ~version
  >>= fun () ->
  App_log.success (fun m ->
      m "The pull-request #%s of package %a %a has been undrafted at %s\n" pr_id
        Text.Pp.name pkg_name Text.Pp.version version url);
  Ok 0

(* Command line interface *)

open Cmdliner

let doc =
  "Publish package distribution archives and derived artefacts. $(b,Warning:) \
   This command is experimental."

let sdocs = Manpage.s_common_options
let exits = Cli.exits
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

let term =
  Term.(
    let open Syntax in
    let+ () = Cli.setup
    and+ opam = Cli.dist_opam
    and+ distrib_file = Cli.dist_file
    and+ opam_repo = Cli.opam_repo
    and+ token = Cli.token
    and+ local_repo = Cli.local_repo
    and+ remote_repo = Cli.remote_repo
    and+ build_dir = Cli.build_dir
    and+ pkg_names = Cli.pkg_names
    and+ dry_run = Cli.dry_run
    and+ yes = Cli.yes in
    undraft ?opam ?distrib_file ?opam_repo ?token ?local_repo ?remote_repo
      ?build_dir ~pkg_names ~dry_run ~yes ()
    |> Cli.handle_error)

let info = Cmd.info "undraft" ~doc ~sdocs ~exits ~man ~man_xrefs
let cmd = Cmd.v info term
