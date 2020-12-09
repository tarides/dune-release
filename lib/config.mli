(*
 * Copyright (c) 2018 Thomas Gazagnaire <thomas@gazagnaire.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

type t = {
  user : string option;
  remote : string option;
  local : Fpath.t option;
  keep_v : bool option;
  auto_open : bool option;
}

val v :
  user:string option ->
  remote_repo:string option ->
  local_repo:string option ->
  Pkg.t list ->
  (t, Bos_setup.R.msg) result

val token : dry_run:bool -> unit -> (Fpath.t, Bos_setup.R.msg) result

val keep_v : bool -> (bool, Bos_setup.R.msg) result

val auto_open : bool -> (bool, Bos_setup.R.msg) result

val load : unit -> (t, Bos_setup.R.msg) result

val save : t -> (unit, Bos_setup.R.msg) result

val pretty_fields : t -> (string * string option) list
(** [pretty_fields t] returns the list of pretty-printed key-value pairs for the
    config [t]. *)

module type S = sig
  val path : build_dir:Fpath.t -> name:string -> version:string -> Fpath.t

  val set :
    dry_run:bool ->
    build_dir:Fpath.t ->
    name:string ->
    version:string ->
    int ->
    (unit, Bos_setup.R.msg) result

  val is_set :
    dry_run:bool ->
    build_dir:Fpath.t ->
    name:string ->
    version:string ->
    (bool, Bos_setup.R.msg) result

  val get :
    dry_run:bool ->
    build_dir:Fpath.t ->
    name:string ->
    version:string ->
    (int, Bos_setup.R.msg) result

  val unset :
    dry_run:bool ->
    build_dir:Fpath.t ->
    name:string ->
    version:string ->
    (unit, Bos_setup.R.msg) result
end

module Draft_release : S

module Draft_pr : S
