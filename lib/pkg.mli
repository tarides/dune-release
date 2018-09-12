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
  ?distrib_uri:string ->
  ?distrib_file:Fpath.t ->
  ?publish_msg:string ->
  ?publish_artefacts:[`Distrib | `Doc | `Alt of string] list ->
  ?distrib:Distrib.t -> ?lint_files:Fpath.t list option ->
  unit -> t

val infer_name: unit -> (string, R.msg) result
(** Infer the name of the projet. *)

val infer_pkg_names: string list -> (string list, R.msg) result
(** Infer the package list. *)

val name : t -> (string, R.msg) result
(** [name p] is [p]'s name. *)

val with_name : t -> string -> t
(** [with_name t n] is [r] such that like [name r] is [n] and [f r] is
    [f t] otherwise. *)

val version : t -> (string, R.msg) result
(** [version p] is [p]'s version string.*)

val tag : t -> (string, R.msg) result

val delegate : t -> (Cmd.t option, R.msg) result
(** [delegate p] is [p]'s delegate. *)

val build_dir : t -> (Fpath.t, R.msg) result
(** [build_dir p] is [p]'s build directory. *)

val opam : t -> (Fpath.t, R.msg) result
(** [opam p] is [p]'s opam file. *)

val opam_descr : t -> (Opam.Descr.t, R.msg) result
(** [opam_descr p] is [p]'s opam description. *)

val opam_homepage: t -> (string option, R.msg) result
val opam_doc: t -> (string option, R.msg) result

val opam_field : t -> string -> (string list option, R.msg) result
(** [opam_field p f] looks up field [f] of [p]'s opam file. *)

val opam_field_hd: t -> string -> (string option, Sos.error) result

val opam_fields : t -> (string list String.map, R.msg) result
(** [opam_fields p] are [p]'s opam file fields. *)

val readmes : t -> (Fpath.t list, R.msg) result
(** [readmes p] are [p]'s readme files. *)

val readme : t -> (Fpath.t, R.msg) result
(** [readme p] is the first element of [readmes p]. *)

val change_logs : t -> (Fpath.t list, R.msg) result
(** [change_logs p] are [p]'s change logs. *)

val change_log : t -> (Fpath.t, R.msg) result
(** [change_log p] is the first element of [change_logs p]. *)

val licenses : t -> (Fpath.t list, R.msg) result
(** [licenses p] are [p]'s license files. *)

val distrib_uri : ?raw:bool -> t -> (string, R.msg) result
(** [distrib_uri p] is [p]'s distribution URI. If [raw] is [true]
    defaults to [false], [p]'s raw URI distribution pattern is
    returned. *)

val distrib_file : dry_run:bool -> t -> (Fpath.t, R.msg) result
(** [distrib_file p] is [p]'s distribution archive. *)

val publish_msg : t -> (string, R.msg) result
(** [publish_msg p] is [p]'s distribution publication message. *)

(** {1 Distribution} *)

val distrib_archive : dry_run:bool -> keep_dir:bool -> t -> (Fpath.t, R.msg) result
(** [distrib_archive ~keep_dir p] creates a distribution archive for
    [p] and returns its path. If [keep_dir] is [true] the repository
    checkout used to create the distribution archive is kept in the
    build directory. *)

val distrib_archive_path: t -> (Fpath.t, Rresult.R.msg) result

val distrib_filename : ?opam:bool -> t -> (Fpath.t, R.msg) result
(** [distrib_filename ~opam p] is a distribution filename for [p].  If
    [opam] is [true] (defaults to [false]), the name follows opam's
    naming conventions. *)

val publish_artefacts : t -> ([`Distrib | `Doc | `Alt of string] list, R.msg) result
(** [publish_artefacts p] are [p]'s publication artefacts. *)

(** {1 Uri} *)

val doc_user_repo_and_path : t -> (string * string * Fpath.t, R.msg) result

val distrib_user_and_repo : t -> (string * string, R.msg) result

type f =
  dry_run:bool ->
  dir:Fpath.t ->
  args:Cmd.t ->
  out:(OS.Cmd.run_out -> (string * OS.Cmd.run_status, Sos.error) result) ->
  t -> (string * OS.Cmd.run_status, Sos.error) result

(** {1 Test} *)

val test : f

(** {1 Build} *)

val build : f

(** {1 Clean} *)

val clean : f

(** {1 Lint} *)

type lint = [ `Std_files |`Opam ]
(** The type for lints. *)

val lint_all : lint list
(** [lint_all] is a list with all lint values. *)

val lint : dry_run:bool -> dir:Fpath.t -> t -> lint list -> (int, R.msg) result
(** [distrib ~ignore_pkg p ~dir lints] performs the lints mentioned in
    [lints] in a directory [dir] on the package [p].  If [ignore_pkg]
    is [true] [p]'s definitions are ignored. *)

(** {1 Tag} *)

val extract_tag : t -> (string, Sos.error) result

(** {1 Dev repo} *)

val dev_repo : t -> (string option, Sos.error) result

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
