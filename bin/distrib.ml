(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup
open Dune_release

let check_archive ~dry_run ~skip_lint ~skip_build ~skip_tests ~pkg_names pkg ar
    =
  Archive.untbz ~dry_run ~clean:true ar >>= fun dir ->
  (if skip_lint then Ok 0
   else Lint.lint_packages ~dry_run ~dir ~todo:Lint.all pkg pkg_names)
  >>= fun c0 ->
  Check.dune_checks ~dry_run ~skip_build ~skip_tests ~pkg_names dir
  >>= fun c1 ->
  match c0 + c1 with
  | 0 -> Sos.delete_dir ~dry_run dir >>= fun () -> Ok 0
  | _ -> Ok 1

let warn_if_vcs_dirty () =
  Cli.warn_if_vcs_dirty
    "Uncommitted changes to files (including dune-project) will not be \
     included in the distribution archive."

let log_footprint pkg archive =
  Pkg.name pkg >>= fun name ->
  Pkg.version pkg >>= fun version ->
  Vcs.get () >>= fun repo ->
  Vcs.commit_id repo ~dirty:false ~commit_ish:"HEAD" >>= fun commit_ish ->
  App_log.blank_line ();
  App_log.success (fun l ->
      l "Distribution for %a %a" Text.Pp.name name Text.Pp.version version);
  App_log.success (fun l -> l "Commit %a" Text.Pp.commit commit_ish);
  App_log.success (fun l -> l "Archive %a" Text.Pp.path archive);
  Ok ()

let log_wrote_archive ar =
  App_log.success (fun m -> m "Wrote archive %a" Text.Pp.path ar);
  Ok ()

let distrib ?build_dir ~dry_run ~pkg_names ~version ~tag ~keep_v ~keep_dir
    ~skip_lint ~skip_build ~skip_tests ~include_submodules () =
  App_log.status (fun l -> l "Building source archive");
  warn_if_vcs_dirty () >>= fun () ->
  Config.keep_v ~keep_v >>= fun keep_v ->
  let pkg = Pkg.v ~dry_run ?version ~keep_v ?build_dir ?tag () in
  Pkg.distrib_archive ~dry_run ~keep_dir ~include_submodules pkg >>= fun ar ->
  log_wrote_archive ar >>= fun () ->
  check_archive ~dry_run ~skip_lint ~skip_build ~skip_tests ~pkg_names pkg ar
  >>= fun errs ->
  log_footprint pkg ar >>= fun () -> Ok errs

(* Command line interface *)

open Cmdliner

let doc = "Create a package distribution archive"
let sdocs = Manpage.s_common_options
let exits = Cli.exits

let envs =
  [
    Cmd.Env.info "DUNE_RELEASE_BZIP2"
      ~doc:
        "The $(b,bzip2) tool to use to compress the\n\
        \    archive. Gets the archive on stdin and must output the result on\n\
        \    standard out.";
    Cmd.Env.info "DUNE_RELEASE_TAR"
      ~doc:
        "The $(b,tar) tool to use to unarchive a tbz\n\
        \    archive (archive creation itself is handled by dune-release).";
  ]

let man_xrefs = [ `Main ]

let man =
  [
    `S Manpage.s_description;
    `P
      "The $(tname) command creates a package distribution archive in the \
       build directory of the package.  The generated archive should be \
       bit-wise reproducible. There are however a few caveats, see the section \
       about this further down.";
    `P
      "More detailed information about the archive creation process and its \
       customization can be found in dune-release's API documentation.";
    `P
      "Once the archive is created it is unpacked in the build directory, \
       linted and the package is built using the package description contained \
       in the archive. The build will use the default package configuration so \
       it may fail in the current environment without this necessarily \
       implying an actual problem with the distribution; one should still \
       worry about it though. These checks can be prevented by using the \
       $(b,--skip-lint) and $(b,--skip-build) options.";
    `S "REPRODUCIBLE DISTRIBUTION ARCHIVES";
    `P
      "Given the package name, the HEAD commit identifier and the version \
       string, the $(tname) command should always generate the same archive.";
    `P
      "More precisely, files are added to the archive using a well defined \
       order on path names. Their file permissions are either 0o775 for \
       directories and files that are executable for the user in the HEAD \
       repository checkout or 0o664 for those that are not. Their modification \
       times are set to the commit date (note that if git is used, git-log(1) \
       shows the author date which may not coincide). No other file metadata \
       is recorded.";
    `P
      "This should ensure that the resulting archive is bit-wise identical \
       regardless of the context in which it is created. However this may fail \
       for one or more of the following reasons:";
    `I
      ( "Non-reproducible distribution massage",
        "The package distribution massaging hook relies on external factors \
         that are not captured by the source repository checkout. For example \
         external data files, environment variables, etc." );
    `I
      ( "File paths with non US-ASCII characters",
        "If these paths are encoded in UTF-8, different file systems may \
         return the paths with different Unicode normalization forms which \
         could yield different byte serializations in the archive (note that \
         this could be lifted at the cost of a dependency on Uunf)." );
    `I
      ( "The bzip2 utility",
        "The archive is compressed using the bzip2 utility. Reproducibility \
         relies on bzip2 to be a reproducible function across platforms." );
  ]

let term =
  Term.(
    let open Syntax in
    let+ () = Cli.setup
    and+ (`Dry_run dry_run) = Cli.dry_run
    and+ (`Build_dir build_dir) = Cli.build_dir
    and+ (`Package_names pkg_names) = Cli.pkg_names
    and+ (`Package_version version) = Cli.pkg_version
    and+ (`Dist_tag tag) = Cli.dist_tag
    and+ (`Keep_v keep_v) = Cli.keep_v
    and+ (`Keep_build_dir keep_dir) = Cli.keep_build_dir
    and+ (`Skip_lint skip_lint) = Cli.skip_lint
    and+ (`Skip_build skip_build) = Cli.skip_build
    and+ (`Skip_tests skip_tests) = Cli.skip_tests
    and+ (`Include_submodules include_submodules) = Cli.include_submodules in
    distrib ?build_dir ~dry_run ~pkg_names ~version ~tag ~keep_v ~keep_dir
      ~skip_lint ~skip_build ~skip_tests ~include_submodules ()
    |> Cli.handle_error)

let info = Cmd.info "distrib" ~doc ~sdocs ~exits ~envs ~man ~man_xrefs
let cmd = Cmd.v info term

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
