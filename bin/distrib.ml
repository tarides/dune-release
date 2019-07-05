(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup
open Dune_release

let lint_distrib ~dry_run ~dir ~pkg_names pkg =
  App_log.blank_line ();
  App_log.status (fun m -> m "Linting distrib in %a" Fpath.pp dir);
  List.fold_left (fun acc name ->
      acc >>= fun acc ->
      let pkg = Pkg.with_name pkg name in
      Lint.lint_pkg ~dry_run ~dir pkg Lint.all >>= fun x ->
      Ok (acc + x)
    ) (Ok 0) pkg_names

let build_distrib ~dry_run ~dir pkg =
  App_log.blank_line ();
  App_log.status (fun m -> m "Building package in %a" Fpath.pp dir);
  let args = Cmd.empty (* XXX(samoht): Cmd.(v "--dev") *) in
  let out = OS.Cmd.out_string in
  Pkg.build ~dry_run pkg ~dir ~args ~out >>= function
  | (_, (_, `Exited 0)) ->
      Logs.app (fun m -> m "%a package builds" Text.Pp.status `Ok); Ok 0
  | (stdout, _) ->
      Logs.app (fun m -> m "%s@\n%a package builds"
                   stdout Text.Pp.status `Fail); Ok 1

let test_distrib ~dry_run ~dir pkg =
  App_log.blank_line ();
  App_log.status (fun m -> m "Running package tests in %a" Fpath.pp dir);
  let out = OS.Cmd.out_string in
  Pkg.test ~dry_run ~dir ~args:Cmd.empty ~out pkg >>= function
  | (_, (_, `Exited 0)) ->
      Logs.app (fun m -> m "%a package tests" Text.Pp.status `Ok); Ok 0
  | (stdout, _) ->
      Logs.app (fun m -> m "%s@\n%a package tests" stdout Text.Pp.status `Fail);
      Ok 1

let check_archive ~dry_run ~skip_lint ~skip_build ~skip_tests ~pkg_names pkg ar =
  Archive.untbz ~dry_run ~clean:true ar >>= fun dir ->
  Pkg.infer_pkg_names dir pkg_names  >>= fun pkg_names ->
  (if skip_lint then Ok 0 else lint_distrib ~dry_run ~dir ~pkg_names pkg)
  >>= fun c0 -> (if skip_build then Ok 0 else build_distrib ~dry_run ~dir pkg)
  >>= fun c1 -> (if skip_tests || skip_build then Ok 0 else
                 test_distrib ~dry_run ~dir pkg)
  >>= fun c2 -> match c0 + c1 + c2 with
  | 0 -> Sos.delete_dir ~dry_run dir >>= fun () -> Ok 0
  | _ -> Ok 1

let warn_if_vcs_dirty ()=
  Cli.warn_if_vcs_dirty "The distribution archive may be inconsistent."

let log_footprint pkg archive =
  Pkg.name pkg
  >>= fun name -> Pkg.version pkg
  >>= fun version -> Vcs.get ()
  >>= fun repo -> Vcs.commit_id repo ~dirty:false ~commit_ish:"HEAD"
  >>= fun commit_ish ->
  App_log.blank_line ();
  App_log.success (fun l -> l "Distribution for %a %a" Text.Pp.name name Text.Pp.version version);
  App_log.success (fun l -> l "Commit %a" Text.Pp.commit commit_ish);
  App_log.success (fun l -> l "Archive %a" Text.Pp.path archive);
  Ok ()

let log_wrote_archive ar =
  App_log.success (fun m -> m "Wrote archive %a" Text.Pp.path ar); Ok ()

let distrib
    () dry_run build_dir name pkg_names version tag keep_v
    keep_dir skip_lint skip_build skip_tests
  =
  begin
    App_log.status (fun l -> l "Building source archive");
    Config.keep_v keep_v >>= fun keep_v ->
    let pkg = Pkg.v ~dry_run ?name ?version ~keep_v ?build_dir ?tag () in
    Pkg.distrib_archive ~dry_run ~keep_dir pkg
    >>= fun ar -> log_wrote_archive ar
    >>= fun () ->
    check_archive ~dry_run ~skip_lint ~skip_build ~skip_tests ~pkg_names pkg ar
    >>= fun errs -> log_footprint pkg ar
    >>= fun () -> (if dry_run then Ok () else warn_if_vcs_dirty ())
    >>= fun () -> Ok errs
  end
  |> Cli.handle_error

(* Command line interface *)

open Cmdliner

let keep_build_dir =
  let doc = "Keep the distribution build directory after successful archival."
  in
  Arg.(value & flag & info ["keep-build-dir"] ~doc)

let skip_lint =
  let doc = "Do not lint the archive distribution." in
  Arg.(value & flag & info ["skip-lint"] ~doc)

let skip_build =
  let doc = "Do not try to build the package from the archive." in
  Arg.(value & flag & info ["skip-build"] ~doc)

let skip_tests =
  let doc = "Do not try to build and run the package tests from the archive.
             Implied by $(b,--skip-build)."
  in
  Arg.(value & flag & info ["skip-tests"] ~doc)

let doc = "Create a package distribution archive"
let sdocs = Manpage.s_common_options
let exits = Cli.exits
let envs =
  [ Term.env_info "DUNE_RELEASE_BZIP2" ~doc:"The $(b,bzip2) tool to use to compress the
    archive. Gets the archive on stdin and must output the result on
    standard out.";
    Term.env_info "DUNE_RELEASE_TAR" ~doc:"The $(b,tar) tool to use to unarchive a tbz
    archive (archive creation itself is handled by dune-release)."; ]

let man_xrefs = [ `Main ]
let man =
  [ `S Manpage.s_description;
    `P "The $(tname) command creates a package distribution
        archive in the build directory of the package.  The generated
        archive should be bit-wise reproducible. There are however a few
        caveats, see the section about this further down.";
    `P "More detailed information about the archive creation process and its
        customization can be found in dune-release's API documentation.";
    `P "Once the archive is created it is unpacked in the build directory,
        linted and the package is built using the package description
        contained in the archive. The build will use the default package
        configuration so it may fail in the current environment
        without this necessarily implying an actual problem with the
        distribution; one should still worry about it though.
        These checks can be prevented by using the $(b,--skip-lint) and
        $(b,--skip-build) options.";
    `S "REPRODUCIBLE DISTRIBUTION ARCHIVES";
    `P "Given the package name, the HEAD commit identifier
        and the version string, the $(tname) command should always
        generate the same archive.";
    `P "More precisely, files are added to the archive using a well
        defined order on path names. Their file permissions are either
        0o775 for directories and files that are executable for the user
        in the HEAD repository checkout or 0o664 for those that are not.
        Their modification times are set to the commit date (note that if
        git is used, git-log(1) shows the author date which may not
        coincide). No other file metadata is recorded.";
    `P "This should ensure that the resulting archive is bit-wise
        identical regardless of the context in which it is
        created. However this may fail for one or more of the
        following reasons:";
    `I ("Non-reproducible distribution massage", "The package
         distribution massaging hook relies on external factors
         that are not captured by the source repository checkout.
         For example external data files, environment variables, etc.");
    `I ("File paths with non US-ASCII characters",
        "If these paths are encoded in UTF-8, different file systems
         may return the paths with different Unicode normalization
         forms which could yield different byte serializations in the
         archive (note that this could be lifted at the cost of a
         dependency on Uunf).");
    `I ("The bzip2 utility", "The archive is compressed using the bzip2 utility.
         Reproducibility relies on bzip2 to be a reproducible function
         across platforms."); ]

let cmd =
  Term.(pure distrib $ Cli.setup $ Cli.dry_run $
        Cli.build_dir $ Cli.dist_name $ Cli.pkg_names
        $ Cli.pkg_version $ Cli.dist_tag $ Cli.keep_v
        $ keep_build_dir $ skip_lint $ skip_build $ skip_tests),
  Term.info "distrib" ~doc ~sdocs ~exits ~envs ~man ~man_xrefs

(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli

   Permission to use, copy, modify, and/or distribute this software for any
   purpose with or without fee is hereby granted, provided that the above
   copyright notice and this permission notice appear in all copies.

   THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
   WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
   MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
   ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
   WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
   ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
   OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
  ---------------------------------------------------------------------------*)
