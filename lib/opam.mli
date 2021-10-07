(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

(** opam helpers. *)

open Bos_setup

(** {1:cmd Command} *)

val cmd : Cmd.t
(** [cmd] is a command for [opam]. *)

(** {1:publish Publish} *)

val prepare_package :
  build_dir:Fpath.t ->
  dry_run:bool ->
  version:Version.t ->
  Vcs.t ->
  string ->
  (unit, R.msg) result

val prepare :
  dry_run:bool ->
  ?msg:string ->
  local_repo:Fpath.t ->
  remote_repo:string ->
  opam_repo:string * string ->
  version:Version.t ->
  tag:Vcs.Tag.t ->
  string list ->
  (Vcs.commit_ish, R.msg) result
(** [prepare ~local_repo ~version pkgs] adds the packages [pkg.version] to a new
    branch in the local opam repository [local_repo], using the commit message
    [msg] (if any). Return the new branch. *)

(** {1:files Files} *)

(** opam files *)
module File : sig
  (** {1:file opam file} *)

  val fields : dry_run:bool -> Fpath.t -> (string list String.map, R.msg) result
  (** [fields f] returns a simplified model of the fields of the opam file [f].
      Note that the [depends:] and [depopts:] fields are returned without
      version constraints. *)
end

(** [descr] files. *)
module Descr : sig
  (** {1:descr Descr file} *)

  type t = string * string option
  (** The type for opam [descr] files, the package synopsis and the description. *)

  val of_string : string -> (t, R.msg) result
  (** [of_string s] is a description from the string [s]. *)

  val to_string : t -> string
  (** [to_string d] is [d] as a string. *)

  val of_readme_file : Fpath.t -> (t, R.msg) result
  (** [of_readme_file f] extracts an opam description file from a readme file
      [f] using {!Text.flavour_of_fpath}. *)
end

(** [url] files. *)
module Url : sig
  (** {1:url Url file} *)

  val with_distrib_file :
    dry_run:bool -> uri:string -> Fpath.t -> (OpamFile.URL.t, R.msg) result
  (** [with_distrib_file ~uri f] is an URL file for URI [uri] with the checksum
      of file [f]. *)
end

(** Opam version. *)
module Version : sig
  type t = V1_2_2 | V2  (** Supported opam versions. *)

  val pp : Format.formatter -> t -> unit

  val equal : t -> t -> bool

  val of_string : string -> (t, R.msg) result
  (** [of_string s] returns the supported opam version parsed from [s] or return
      the associated error message. *)

  val cli : (t, R.msg) result Lazy.t
  (** [cli] is the output of [opam --version]. *)
end

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
