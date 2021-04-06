open Bos_setup

let build ~dry_run ~dir pkg_names =
  let out = OS.Cmd.out_string in
  let build_result =
    App_log.blank_line ();
    App_log.status (fun m -> m "Building package in %a" Fpath.pp dir);
    Pkg.build ~dry_run pkg_names ~dir ~args:Cmd.empty ~out
  in
  build_result >>= function
  | _, (_, `Exited 0) ->
      App_log.report_status `Ok (fun m -> m "package(s) build");
      Ok 0
  | stdout, _ ->
      Logs.app (fun m -> m "%s" stdout);
      App_log.report_status `Fail (fun m -> m "package(s) build");
      Ok 1

let test ~dry_run ~dir pkg_names =
  let out = OS.Cmd.out_string in
  let test_result =
    App_log.blank_line ();
    App_log.status (fun m -> m "Running package tests in %a" Fpath.pp dir);
    Pkg.test ~dry_run ~dir ~args:Cmd.empty ~out pkg_names
  in
  test_result >>= function
  | _, (_, `Exited 0) ->
      App_log.report_status `Ok (fun m -> m "package(s) pass the tests");
      Ok 0
  | stdout, _ ->
      Logs.app (fun m -> m "%s" stdout);
      App_log.report_status `Fail (fun m -> m "package(s) pass the tests");
      Ok 1

let dune_checks ~dry_run ~skip_build ~skip_tests ~pkg_names dir =
  Pkg.infer_pkg_names dir pkg_names >>= fun pkg_names ->
  (if skip_build then Ok 0 else build ~dry_run ~dir pkg_names) >>= fun c1 ->
  (if skip_tests || skip_build then Ok 0 else test ~dry_run ~dir pkg_names)
  >>| fun c2 -> if c1 + c2 = 0 then 0 else 1

let pkg_creation_check ?tag ?version ~keep_v ?build_dir dir =
  let check_creation () =
    Pkg.try_infer_name Fpath.(v ".") >>= function
    | None -> Rresult.R.error_msgf Pkg.infer_name_err
    | Some _ -> (
        match Pkg.v ~dry_run:false ?tag ?version ~keep_v ?build_dir () with
        | pkg -> Ok pkg
        | exception Invalid_argument err -> Rresult.R.error_msgf "%s" err)
  in
  R.join @@ Sos.with_dir ~dry_run:false dir check_creation ()

let opam_file_check ~dir pkg =
  let check () =
    let ok_needed = Pkg.infer_github_repo_uri pkg in
    Pkg.opam pkg >>| fun main_opam ->
    (* Pkg.opam only returns an error if something is wrong internally *)
    match ok_needed with
    | Ok _ ->
        App_log.report_status `Ok (fun m ->
            m "The dev-repo field of %a contains a github uri." Text.Pp.path
              main_opam);
        0
    | Error (`Msg err) ->
        App_log.report_status `Fail (fun m ->
            m
              "main package %a is not dune-release compatible. %s \n\
               Have you provided a github uri in the dev-repo field of your \
               main opam file? If you don't use github, you can still use \
               dune-release for everything but for publishing your release on \
               the web. In that case, have a look at `dune-release \
               delegate-info`."
              Text.Pp.path main_opam err);
        1
  in
  R.join @@ Sos.with_dir ~dry_run:false dir check ()

let dune_project_check dir =
  let check () =
    Pkg.dune_project_name (Fpath.v ".") >>| function
    | Some _ ->
        App_log.report_status `Ok (fun m ->
            m "The dune project contains a name stanza.");
        0
    | None ->
        App_log.report_status `Fail (fun m ->
            m "The dune project doesn't contain a name stanza. Please, add one.");
        1
  in
  R.join @@ Sos.with_dir ~dry_run:false dir check ()

let check_project ~pkg_names ~skip_lint ~skip_build ~skip_tests ?tag ?version
    ~keep_v ?build_dir ~dir () =
  match pkg_creation_check ?tag ?version ~keep_v ?build_dir dir with
  | Error (`Msg err) ->
      App_log.report_status `Fail (fun m -> m "%s" err);
      Ok 1
  | Ok pkg ->
      App_log.status (fun m -> m "Checking dune-release compatibility.");
      opam_file_check ~dir pkg >>= fun opam_file_exit ->
      dune_project_check dir >>= fun dune_project_exit ->
      dune_checks ~dry_run:false ~skip_build ~skip_tests ~pkg_names dir
      >>= fun dune_exit ->
      if skip_lint then Ok 0
      else
        Lint.lint_packages ~dry_run:false ~dir ~todo:Lint.all pkg pkg_names
        >>| fun lint_exit ->
        opam_file_exit + dune_project_exit + dune_exit + lint_exit
