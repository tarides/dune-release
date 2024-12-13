(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

(** {!Cmdliner} and common definitions for commands. *)

open Cmdliner
open Rresult

(** {1 Converters and options} *)

val path_arg : Fpath.t Arg.conv
(** [path_arg] is a path argument converter. *)

val named : ('a -> 'b) -> 'a Cmdliner.Term.t -> 'b Cmdliner.Term.t
(** Use this to wrap your arguments in a polymorphic variant constructor to
    avoid confusion when they are later passed to your main function. Example:
    [named (fun x -> `My_arg x) Arg.(value ...)] *)

val no_auto_open : [ `No_auto_open of bool Dune_release.Config.Cli.t ] Term.t
(** A [--no-auto-open] option to disable opening of the opam-repository PR in
    the browser. *)

val version : Dune_release.Version.t Arg.conv
(** [version] is a converter for parsing version specifiers *)

val pkg_names : [ `Package_names of string list ] Term.t
(** A [--pkg-names] option to specify the packages to release. *)

val pkg_version : [ `Package_version of Dune_release.Version.t option ] Term.t
(** A [--pkg-version] option to specify the packages version. *)

val keep_v : [ `Keep_v of bool Dune_release.Config.Cli.t ] Term.t
(** A [--keep-v] option to not drop the 'v' at the beginning of version strings. *)

val dist_tag : [ `Dist_tag of Dune_release.Vcs.Tag.t option ] Term.t
(** A [--tag] option to define the tag from which the distribution is or will be
    built. *)

val dist_file : [ `Dist_file of Fpath.t option ] Term.t
(** A [--dist-file] option to define the distribution archive file. *)

val dist_uri : [ `Dist_uri of string option ] Term.t
(** A [--dist-uri] option to define the distribution archive URI on the WWW. *)

val dist_opam : [ `Dist_opam of Fpath.t option ] Term.t
(** An [--dist-opam] option to define the opam file. *)

val readme : [ `Readme of Fpath.t option ] Term.t
(** A [--readme] option to define the readme. *)

val change_log : [ `Change_log of Fpath.t option ] Term.t
(** A [--change-log] option to define the change log. *)

val opam : [ `Opam of Fpath.t option ] Term.t
(** An [--opam] option to define an opam file. *)

val build_dir : [ `Build_dir of Fpath.t option ] Term.t
(** A [--build-dir] option to define the build directory. *)

val publish_msg : [ `Publish_msg of string option ] Term.t
(** A [--msg] option to define a publication message. *)

val token : [ `Token of string Dune_release.Config.Cli.t option ] Term.t
(** A [--token] option to define the github token. *)

val dry_run : [ `Dry_run of bool ] Term.t
(** A [--dry-run] option to do not perform any action. *)

val draft : [ `Draft of bool ] Term.t
(** A [--draft] option to produce a draft release. *)

val yes : [ `Yes of bool ] Term.t
(** A [--yes] option to skip confirmation prompts. *)

val include_submodules : [ `Include_submodules of bool ] Term.t
(** A [--include-submodules] flag to include submodules in the distrib tarball *)

val user : [ `User of string option ] Term.t
(** A [--user] option to define the name of the GitHub account where to push new
    opam-repository branches. *)

val local_repo :
  [ `Local_repo of Fpath.t Dune_release.Config.Cli.t option ] Term.t
(** A [--local-repo] option to define the location of the local fork of
    opam-repository. *)

val dev_repo : [ `Dev_repo of string option ] Term.t
(** A [--dev-repo] option to define the Github opam-repository to which packages
    should be released. *)

val remote_repo :
  [ `Remote_repo of string Dune_release.Config.Cli.t option ] Term.t
(** A [--remote-repo] option to define the location of the remote fork of
    opam-repository. *)

val opam_repo : [ `Opam_repo of (string * string) option ] Term.t
(** A [--opam-repo] option to define the Github opam-repository to which
    packages should be released. *)

val skip_lint : [> `Skip_lint of bool ] Term.t
(** a [--skip-lint] option to skip the linting *)

val skip_build : [> `Skip_build of bool ] Term.t
(** a [--skip-build] option to skip checking the build *)

val skip_tests : [> `Skip_tests of bool ] Term.t
(** a [--skip-test] option to skip checking the tests *)

val skip_change_log : [> `Skip_change_log of bool ] Term.t
(** a [--skip-change-log] option to skip validation of change-log *)

val keep_build_dir : [> `Keep_build_dir of bool ] Term.t
(** a [--keep-build-dir] flag to keep the build directory used for the archive
    check. *)

(** {1 Terms} *)

val setup : unit Term.t
(** [setup env] defines a basic setup common to all commands. The setup does, by
    side effect, set {!Logs} log verbosity, adjusts colored output and sets the
    current working directory. *)

(** {1 Warnings and errors} *)

val warn_if_vcs_dirty : string -> (unit, R.msg) result
(** [warn_if_vcs_dirty msg] warns with [msg] if the VCS is dirty. *)

val handle_error : (int, R.msg) result -> int
(** [handle_error r] is [r]'s result or logs [r]'s error and returns [3]. *)

val exits : Cmd.Exit.info list
(** [exits] is are the exit codes common to all commands. *)

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
