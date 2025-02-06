(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

let format_linebreaks s = String.split_on_char '\n' s |> String.concat "\n  "

open Bos_setup
open Cmdliner
open Dune_release

(* Converters and arguments *)

let path_arg = Arg.conv Fpath.(of_string, pp)

let dir_path_arg =
  let dir_parse = Arg.(conv_parser dir) in
  let parse s = dir_parse s >>= Fpath.of_string in
  Arg.conv ~docv:"DIR" (parse, Fpath.pp)

let config term = Cmdliner.Term.map Dune_release.Config.Cli.make term

let config_opt term =
  Cmdliner.Term.map (Stdext.Option.map ~f:Dune_release.Config.Cli.make) term

let tag =
  Arg.conv ~docv:"VCS_TAG" ((fun s -> Ok (Vcs.Tag.of_string s)), Vcs.Tag.pp)

let dist_tag =
  let doc =
    "The tag from which the distribution archive is or will be built."
  in
  Arg.(value & opt (some tag) None & info [ "t"; "tag" ] ~doc ~docv:"DIST_TAG")

let pkg_names =
  let doc =
    "The names $(docv) of the opam packages to release. If absent provided by \
     the $(b,*.opam) files present in the current directory."
  in
  let docv = "PKG_NAMES" in
  Arg.(value & opt (list string) [] & info [ "p"; "pkg-names" ] ~doc ~docv)

let version =
  Arg.conv ~docv:"An OPAM compatible version string"
    ((fun s -> Ok (Version.of_string s)), Version.pp)

let pkg_version =
  let doc =
    "The version $(docv) of the opam package. If absent it is guessed from the \
     tag."
  in
  let docv = "PKG_VERSION" in
  Arg.(value & opt (some version) None & info [ "V"; "pkg-version" ] ~doc ~docv)

let opam =
  let doc =
    "The opam file to use. If absent uses the default opam file mentioned in \
     the package description."
  in
  let docv = "FILE" in
  Arg.(value & opt (some path_arg) None & info [ "opam" ] ~doc ~docv)

let token =
  let doc =
    "The github token to use. The regular case is to have a locally store the \
     github token that $(b,dune-release) can automatically use and to not set \
     this option. This option is used to override the local configuration \
     token for example as part of a Github Actions workflow where the github \
     token is provided through an environment variable."
  in
  let docv = "TOKEN" in
  let env = Cmd.Env.info "DUNE_RELEASE_GITHUB_TOKEN" in
  let arg =
    Arg.(value & opt (some string) None & info [ "token" ] ~doc ~docv ~env)
  in
  config_opt arg

let keep_v =
  let doc = "Do not drop the initial 'v' in the version string." in
  let arg = Arg.(value & flag & info [ "keep-v" ] ~doc) in
  config arg

let no_auto_open =
  let doc = "Do not open a browser to view the new pull-request." in
  let arg = Arg.(value & flag & info [ "no-auto-open" ] ~doc) in
  config arg

let dist_file =
  let doc =
    "The package distribution archive. If absent the file \
     $(i,BUILD_DIR)/$(i,NAME)-$(i,VERSION).tbz (see options $(b,--build-dir), \
     $(b,--dist-name) and $(b,--dist-version))."
  in
  let docv = "FILE" in
  Arg.(value & opt (some path_arg) None & info [ "dist-file" ] ~doc ~docv)

let dist_opam =
  let doc =
    "opam file to use for the distribution. If absent uses the opam file \
     mentioned in the package description that corresponds to the distribution \
     package name $(i,NAME) (see option $(b,--dist-name))."
  in
  let docv = "FILE" in
  Arg.(value & opt (some path_arg) None & info [ "dist-opam" ] ~doc ~docv)

let dist_uri =
  let doc =
    "The distribution archive URI on the WWW. By default, this value is \
     collected from the result of $(b,dune-release publish) or inferred from \
     the package description. Use this option to override this behaviour. \
     Useful if you have a custom release workflow or if your project is not \
     hosted on Github for example."
  in
  let docv = "URI" in
  Arg.(value & opt (some string) None & info [ "dist-uri" ] ~doc ~docv)

let readme =
  let doc =
    "The readme to use. If absent, provided by the package description."
  in
  let docv = "FILE" in
  Arg.(value & opt (some path_arg) None & info [ "readme" ] ~doc ~docv)

let change_log =
  let doc =
    "The change log to use. If absent, provided by the package description."
  in
  let docv = "FILE" in
  Arg.(value & opt (some path_arg) None & info [ "change-log" ] ~doc ~docv)

let build_dir =
  let doc =
    "Specifies the build directory $(docv). If absent, provided by the package \
     description."
  in
  let docv = "BUILD_DIR" in
  Arg.(value & opt (some path_arg) None & info [ "build-dir" ] ~doc ~docv)

let publish_msg =
  let doc =
    "The publication message $(docv). Defaults to the change log of the last \
     version (see $(b,dune-release log -l))."
  in
  let docv = "MSG" in
  Arg.(value & opt (some string) None & info [ "m"; "message" ] ~doc ~docv)

let dry_run =
  let doc =
    "Don't actually perform any action, just show what would be done."
  in
  Arg.(value & flag & info [ "dry-run" ] ~doc)

let draft =
  let doc =
    "Produce a draft release that cannot be merged accidentally and has to be \
     undrafted before proceeding with the actual release. $(b,Warning:) This \
     feature is experimental."
  in
  Arg.(value & flag & info [ "draft" ] ~doc)

let yes =
  let doc = "Do not prompt for confirmation and keep going instead" in
  Arg.(value & flag & info [ "y"; "yes" ] ~doc)

let include_submodules =
  let doc = "Include git submodules into the distribution archive" in
  Arg.(value & flag & info [ "include-submodules" ] ~doc)

let user =
  let doc =
    "the name of the GitHub account where to push new opam-repository \
     branches. " ^ Deprecate.Config_user.option_doc
  in
  Arg.(value & opt (some string) None & info [ "u"; "user" ] ~doc ~docv:"USER")

let local_repo =
  let doc = "Location of the local fork of opam-repository" in
  let env = Cmd.Env.info "DUNE_RELEASE_LOCAL_REPO" in
  let arg =
    Arg.(
      value
      & opt (some dir_path_arg) None
      & info ~env [ "l"; "local-repo" ] ~doc ~docv:"PATH")
  in
  config_opt arg

let remote_repo =
  let doc = "Location of the remote fork of opam-repository" in
  let env = Cmd.Env.info "DUNE_RELEASE_REMOTE_REPO" in
  let arg =
    Arg.(
      value
      & opt (some string) None
      & info ~env [ "r"; "remote-repo" ] ~doc ~docv:"URI")
  in
  config_opt arg

let dev_repo =
  let doc = "Location of the dev repo of the current package" in
  let env = Cmd.Env.info "DUNE_RELEASE_DEV_REPO" in
  Arg.(
    value & opt (some string) None & info ~env [ "dev-repo" ] ~doc ~docv:"URI")

let opam_repo =
  let doc =
    "The Github opam-repository to which packages should be released. Use this \
     to release to a custom repo. Useful for testing purposes."
  in
  let docv = "GITHUB_USER_OR_ORG/REPO_NAME" in
  let env = Cmd.Env.info "DUNE_RELEASE_OPAM_REPO" in
  Arg.(
    value
    & opt (some (pair ~sep:'/' string string)) None
    & info ~env [ "opam-repo" ] ~doc ~docv)

let skip_lint =
  let doc = "Do not lint the archive distribution." in
  Arg.(value & flag & info [ "skip-lint" ] ~doc)

let skip_build =
  let doc = "Do not try to build the package from the archive." in
  Arg.(value & flag & info [ "skip-build" ] ~doc)

let skip_tests =
  let doc =
    "Do not try to build and run the package tests from the archive. Implied \
     by $(b,--skip-build)."
  in
  Arg.(value & flag & info [ "skip-tests" ] ~doc)

let skip_change_log =
  let doc = "Do not check that the change log can be parsed" in
  Arg.(value & flag & info [ "skip-change-log" ] ~doc)

let keep_build_dir =
  let doc =
    "Keep the distribution build directory after successful archival."
  in
  Arg.(value & flag & info [ "keep-build-dir" ] ~doc)

(* Terms *)

(* use cmdliner evaluation error *)

let setup =
  let style_renderer =
    let env = Cmd.Env.info "DUNE_RELEASE_COLOR" in
    Fmt_cli.style_renderer ~docs:Manpage.s_common_options ~env ()
  in
  let log_level =
    let env = Cmd.Env.info "DUNE_RELEASE_VERBOSITY" in
    Logs_cli.level ~docs:Manpage.s_common_options ~env ()
  in
  let cwd =
    let doc = "Change to directory $(docv) before doing anything." in
    let docv = "DIR" in
    Arg.(
      value
      & opt (some path_arg) None
      & info [ "C"; "pkg-dir" ] ~docs:Manpage.s_common_options ~doc ~docv)
  in
  Term.(
    ret
      (let open Syntax in
       let+ style_renderer = style_renderer
       and+ log_level = log_level
       and+ cwd = cwd in
       Fmt_tty.setup_std_outputs ?style_renderer ();
       Logs.set_level log_level;
       Logs.set_reporter (Logs_fmt.reporter ~app:Fmt.stdout ());
       Logs.info (fun m -> m "dune-release %%VERSION%% running");
       match cwd with
       | None -> `Ok ()
       | Some dir -> (
           match OS.Dir.set_current dir with
           | Ok () -> `Ok ()
           | Error (`Msg m) -> `Error (false, m))))

(* Error handling *)

let warn_if_vcs_dirty msg =
  Vcs.get () >>= fun repo ->
  Vcs.is_dirty repo >>= function
  | false -> Ok ()
  | true ->
      Logs.warn (fun m -> m "The repo is %a. %a" Text.Pp.dirty () Fmt.text msg);
      Ok ()

let handle_error = function
  | Ok 0 -> if Logs.err_count () > 0 then 3 else 0
  | Ok n -> n
  | Error _ as r ->
      Logs.on_error
        ~pp:(fun fmt (`Msg msg) ->
          format_linebreaks msg |> Format.pp_print_string fmt)
        ~use:(fun (`Msg _) -> 3)
        r

let exits =
  Cmd.Exit.info 3 ~doc:"on indiscriminate errors reported on stderr."
  :: Cmd.Exit.defaults

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
