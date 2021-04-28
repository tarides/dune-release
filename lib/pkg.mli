(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

(** Package descriptions. *)

open Bos_setup

(** {1 Package} *)

type t
(** The type for package descriptions. *)

val infer_name_err : ('a, Format.formatter, unit, unit, unit, 'a) format6

val try_infer_name : Fpath.t -> (string option, [> Rresult.R.msg ]) result
(** [try_infer_name dir] tries to infer the name of the main package in [dir].
    If you already have a package [p], use [name p] instead. *)

val v :
  dry_run:bool ->
  ?name:string ->
  ?version:string ->
  ?tag:string ->
  ?keep_v:bool ->
  ?delegate:Cmd.t ->
  ?build_dir:Fpath.t ->
  ?opam:Fpath.t ->
  ?opam_descr:Fpath.t ->
  ?readme:Fpath.t ->
  ?change_log:Fpath.t ->
  ?license:Fpath.t ->
  ?distrib_file:Fpath.t ->
  ?publish_msg:string ->
  unit ->
  t

val infer_pkg_names : Fpath.t -> string list -> (string list, R.msg) result
(** Infer the package list. *)

val name : t -> (string, R.msg) result
(** [name p] is [p]'s name. *)

val with_name : t -> string -> t
(** [with_name t n] is [r] such that like [name r] is [n] and [f r] is [f t]
    otherwise. *)

val version : t -> (string, R.msg) result
(** [version p] is [p]'s version string.*)

val tag_from_repo :
  ?tag:string -> ?version:string -> unit -> (string, [ `Msg of string ]) result
(** Returns the commit-ish [tag] or [version] (in that order), if any of them is
    provided. If not, returns the commit-ish of the latest tag pointing to HEAD. *)

val tag : t -> (string, R.msg) result

val delegate : t -> (Cmd.t option, R.msg) result
(** [delegate p] is [p]'s delegate. *)

val build_dir : t -> (Fpath.t, R.msg) result
(** [build_dir p] is [p]'s build directory. *)

val opam : t -> (Fpath.t, R.msg) result
(** [opam p] is [p]'s opam file. *)

val opam_descr : t -> (Opam.Descr.t, R.msg) result
(** [opam_descr p] is [p]'s opam description. *)

val opam_homepage : t -> (string option, R.msg) result

val opam_doc : t -> (string option, R.msg) result

val opam_field : t -> string -> (string list option, R.msg) result
(** [opam_field p f] looks up field [f] of [p]'s opam file. *)

val opam_field_hd : t -> string -> (string option, Sos.error) result

val readmes : t -> (Fpath.t list, R.msg) result
(** [readmes p] are [p]'s readme files. *)

val change_logs : t -> (Fpath.t list, R.msg) result
(** [change_logs p] are [p]'s change logs. *)

val change_log : t -> (Fpath.t, R.msg) result
(** [change_log p] is the first element of [change_logs p]. *)

val licenses : t -> (Fpath.t list, R.msg) result
(** [licenses p] are [p]'s license files. *)

val infer_github_distrib_uri : t -> (string, R.msg) result
(** [infer_distrib_uri p] infers [p]'s Github distribution URI from the homepage
    and dev-repo fields. *)

val infer_github_repo : t -> (Github_repo.t, R.msg) result
(** [infer_repo_uri p] infers [p]'s Github remote repository from the homepage
    and dev-repo fields. *)

val distrib_file : dry_run:bool -> t -> (Fpath.t, R.msg) result
(** [distrib_file p] is [p]'s distribution archive. *)

val publish_msg : t -> (string, R.msg) result
(** [publish_msg p] is [p]'s distribution publication message. *)

(** {1 Distribution} *)

val distrib_archive :
  dry_run:bool ->
  keep_dir:bool ->
  include_submodules:bool ->
  t ->
  (Fpath.t, R.msg) result
(** [distrib_archive ~keep_dir p] creates a distribution archive for [p] and
    returns its path. If [keep_dir] is [true] the repository checkout used to
    create the distribution archive is kept in the build directory. *)

val distrib_archive_path : t -> (Fpath.t, Rresult.R.msg) result

val archive_url_path : t -> (Fpath.t, R.msg) result
(** [archive_url_path] is the path to the file where the archive download URL is
    saved *)

val distrib_filename : ?opam:bool -> t -> (Fpath.t, R.msg) result
(** [distrib_filename ~opam p] is a distribution filename for [p]. If [opam] is
    [true] (defaults to [false]), the name follows opam's naming conventions. *)

(** {1 Uri} *)

val doc_uri : t -> (string, Bos_setup.R.msg) result

val doc_dir : Fpath.t

val github_doc_owner_repo_and_path :
  t -> (string * string * Fpath.t, R.msg) result

type f =
  dry_run:bool ->
  dir:Fpath.t ->
  args:Cmd.t ->
  out:(OS.Cmd.run_out -> (string * OS.Cmd.run_status, Sos.error) result) ->
  ?err:Bos.OS.Cmd.run_err ->
  string list ->
  (string * OS.Cmd.run_status, Sos.error) result

(** {1 Test} *)

val test : f

(** {1 Build} *)

val build : f

(** {1 Version} *)

val extract_version : t -> (string, Sos.error) result
(** [extract_version p] extracts the version identifier from the changelog of
    [p]. *)

(** {1 Dev repo} *)

val dev_repo : t -> (string option, Sos.error) result
(** dev-repo field with the ["git+"] prefix removed. *)

(**/**)

val version_line_re : Re.t

val prepare_opam_for_distrib :
  version:string -> content:string list -> string list

(** {1 Dune project} *)

val dune_project_name : Fpath.t -> (string option, [> Rresult.R.msg ]) result
(** Returns the name stanza entry of the dune project, if any; else, returns
    `None`. Returns an error, if one of the system calls fails. *)

(**/**)

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
