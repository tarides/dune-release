(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup
open Cmdliner
open Dune_release

(* Converters and arguments *)

let path_arg = Arg.conv Fpath.(of_string, pp)

let dist_tag =
  let doc = "The tag from which the distribution archive is built." in
  Arg.(value & opt (some string) None & info ["t"; "tag"] ~doc ~docv:"DIST_TAG")

let dist_name =
  let doc = "The name $(docv) of the distribution. If absent provided by
             i)   the $(i,name) field in $(b,dune-project);
             ii)  the longest prefix of all the $(b,*.opam) files present in the
                  current directory; and
             iii) the first word in the title of $(b,README.md)."
  in
  let docv = "DIST_NAME" in
  Arg.(value & opt (some string) None & info ["n"; "name"] ~doc ~docv)

let pkg_names =
  let doc = "The names $(docv) of the opam packages to release. If absent provided
             by the $(b,*.opam) files present in the current directory."
  in
  let docv = "PKG_NAMES" in
  Arg.(value & opt (list string) [] & info ["p"; "pkg-names"] ~doc ~docv)

let pkg_version =
  let doc = "The version $(docv) of the opam package. If absent it is guessed
             from the tag."
  in
  let docv = "PKG_VERSION" in
  Arg.(value & opt (some string) None & info ["-V"; "pkg-version"] ~doc ~docv)

let opam =
  let doc = "The opam file to use. If absent uses the default opam file
             mentioned in the package description."
  in
  let docv = "FILE" in
  Arg.(value & opt (some path_arg) None & info ["opam"] ~doc ~docv)

let keep_v =
  let doc = "Do not drop the initial 'v' in the version string." in
  Arg.(value & flag & info ["keep-v"] ~doc)

let dist_file =
  let doc = "The package distribution archive. If absent the file
             $(i,BUILD_DIR)/$(i,NAME)-$(i,VERSION).tbz (see options
             $(b,--build-dir), $(b,--dist-name) and $(b,--dist-version))."
  in
  let docv = "FILE" in
  Arg.(value & opt (some path_arg) None & info ["dist-file"] ~doc ~docv)

let dist_opam =
  let doc = "opam file to use for the distribution. If absent uses the opam
             file mentioned in the package description that corresponds to
             the distribution package name $(i,NAME) (see option
             $(b,--dist-name))."
  in
  let docv = "FILE" in
  Arg.(value & opt (some path_arg) None & info ["dist-opam"] ~doc ~docv)

let dist_uri =
  let doc = "The distribution archive URI on the WWW. If absent, provided by the
             package description."
  in
  let docv = "URI" in
  Arg.(value & opt (some string) None & info ["dist-uri"] ~doc ~docv)

let readme =
  let doc = "The readme to use. If absent, provided by the package
             description."
  in
  let docv = "FILE" in
  Arg.(value & opt (some path_arg) None & info ["readme"] ~doc ~docv)

let change_log =
  let doc = "The change log to use. If absent, provided by the package
             description."
  in
  let docv = "FILE" in
  Arg.(value & opt (some path_arg) None & info ["change-log"] ~doc ~docv)

let build_dir =
  let doc = "Specifies the build directory $(docv). If absent, provided by the
             package description."
  in
  let docv = "BUILD_DIR" in
  Arg.(value & opt (some path_arg) None & info ["build-dir"] ~doc ~docv)

let publish_msg =
  let doc = "The publication message $(docv). Defaults to the change
             log of the last version (see $(b,dune-release log -l))."
  in
  let docv = "MSG" in
  Arg.(value & opt (some string) None & info ["m"; "message"] ~doc ~docv)

let dry_run =
  let doc =
    "Don't actually perform any action, just show what would be done."
  in
  Arg.(value & flag & info ["dry-run"] ~doc)

(* Terms *)

let setup style_renderer log_level cwd =
  Fmt_tty.setup_std_outputs ?style_renderer ();
  Logs.set_level log_level;
  Logs.set_reporter (Logs_fmt.reporter ~app:Fmt.stdout ());
  Logs.info (fun m -> m "dune-release %%VERSION%% running");
  match cwd with
  | None -> `Ok ()
  | Some dir ->
      match OS.Dir.set_current dir with
      | Ok () -> `Ok ()
      | Error (`Msg m) -> `Error (false, m) (* use cmdliner evaluation error *)

let setup =
  let style_renderer =
    let env = Arg.env_var "DUNE_RELEASE_COLOR" in
    Fmt_cli.style_renderer ~docs:Manpage.s_common_options ~env ()
  in
  let log_level =
    let env = Arg.env_var "DUNE_RELEASE_VERBOSITY" in
    Logs_cli.level ~docs:Manpage.s_common_options ~env ()
  in
  let cwd =
    let doc = "Change to directory $(docv) before doing anything." in
    let docv = "DIR" in
    Arg.(value & opt (some path_arg) None & info ["C"; "pkg-dir"]
           ~docs:Manpage.s_common_options ~doc ~docv)
  in
  Term.(ret (const setup $ style_renderer $ log_level $ cwd))

(* Verbosity propagation. *)

let propagate_verbosity_to_pkg_file () = match Logs.level () with
| None -> Cmd.(v "-q")
| Some Logs.Info -> Cmd.(v "-v")
| Some Logs.Debug -> Cmd.(v "-v" % "-v")
| Some _ -> Cmd.empty

(* Error handling *)

let warn_if_vcs_dirty msg =
  Vcs.get ()
  >>= fun repo -> Vcs.is_dirty repo
  >>= function
  | false -> Ok ()
  | true ->
      Logs.warn
        (fun m -> m "The repo is %a. %a" Text.Pp.dirty () Fmt.text msg);
      Ok ()

let handle_error = function
| Ok 0 -> if Logs.err_count () > 0 then 3 else 0
| Ok n -> n
| Error _ as r -> Logs.on_error_msg ~use:(fun _ -> 3) r

let exits =
  Term.exit_info 3 ~doc:"on indiscriminate errors reported on stderr." ::
  Term.default_exits

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
