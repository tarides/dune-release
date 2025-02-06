open Bos_setup
open Dune_release

let assert_tag_exists repo tag =
  if Vcs.tag_exists ~dry_run:false repo tag then Ok ()
  else R.error_msgf "%a is not a valid tag" Vcs.Tag.pp tag

let clone_and_checkout_tag repo ~dir ~tag =
  Sos.delete_dir ~dry_run:false ~force:true dir >>= fun () ->
  Vcs.clone ~dry_run:false ~force:true repo ~dir >>= fun () ->
  Vcs.get ~dir () >>= fun clone_vcs ->
  Vcs.checkout ~dry_run:false clone_vcs ~branch:"dune-release-check"
    ~commit_ish:tag

open Cmdliner

let doc = "Check dune-release compatibility"

let man =
  [
    `S Manpage.s_description;
    `P
      "$(tname) checks if the release process with dune-release will be \
       smooth, assuming that in other dune-release commands you'll provide the \
       same options as here (with the exception of [--working-tree]). With the \
       [--working-tree] option, you can perform the check on the current \
       working tree; otherwise, it is performed on the tag from which \
       dune-release creates the distribution tarball.";
  ]

let term =
  Term.(
    let open Syntax in
    let+ pkg_names = Cli.pkg_names
    and+ version = Cli.pkg_version
    and+ tag = Cli.dist_tag
    and+ keep_v = Cli.keep_v
    and+ build_dir = Cli.build_dir
    and+ skip_lint = Cli.skip_lint
    and+ skip_build = Cli.skip_build
    and+ skip_tests = Cli.skip_tests
    and+ skip_change_log = Cli.skip_change_log
    and+ on_working_tree =
      let doc = "Perform the check on the current working tree." in
      Arg.(value & flag & info [ "working-tree" ] ~doc)
    in
    (let dir, clean_up =
       if on_working_tree then (OS.Dir.current (), fun _ -> ())
       else
         let dir =
           let pkg = Pkg.v ~dry_run:true ?tag ?version ?build_dir () in
           Pkg.tag pkg >>= fun inferred_tag ->
           Vcs.get () >>= fun repo ->
           assert_tag_exists repo inferred_tag >>= fun () ->
           (match build_dir with
           | Some dir -> Ok dir
           | None -> Fpath.of_string "_build")
           >>= fun build_directory ->
           let dir = Fpath.(build_directory // v ".dune-release-check") in
           clone_and_checkout_tag repo ~dir ~tag:(Tag inferred_tag)
           >>| fun () -> dir
         in
         let clean_up dir =
           match Sos.delete_dir ~dry_run:false ~force:true dir with
           | Ok _ -> ()
           | Error (`Msg err) ->
               App_log.unhappy (fun l ->
                   l "Auxiliary directory %a could not be deleted: %s"
                     Text.Pp.path dir err)
         in
         (dir, clean_up)
     in
     dir >>= fun dir ->
     Config.keep_v ~keep_v >>= fun keep_v ->
     let check_result =
       Check.check_project ~pkg_names ?tag ?version ~keep_v ?build_dir
         ~skip_lint ~skip_build ~skip_tests ~skip_change_log ~dir ()
     in
     let () = clean_up dir in
     check_result)
    |> R.reword_error_msg (fun err ->
           R.msgf "Error while running `check`: %s" err)
    |> Cli.handle_error)

let info = Cmd.info "check" ~doc ~man
let cmd = Cmd.v info term
