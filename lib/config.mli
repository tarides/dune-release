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
  remote : string;
  local : Fpath.t;
  keep_v : bool option;
  auto_open : bool option;
}

module Opam_repo_fork : sig
  type t = { remote : string; local : Fpath.t }
end

val create : ?pkgs:Pkg.t list -> unit -> (unit, Bos_setup.R.msg) result

module Cli : sig
  type 'a t
  (** Type for configuration values passed through the CLI. *)

  val make : 'a -> 'a t
end

val token :
  token:string Cli.t option ->
  dry_run:bool ->
  unit ->
  (string, Bos_setup.R.msg) result
(** Returns the token value that should be used for github API requests. If a
    [token] was provided via the CLI, it is returned. Otherwise the token file
    in the config dir is looked up. If it exists, its content is returned, if it
    does not, the user is prompted for a token which will be then saved to that
    file. When [dry_run] is [true] it always returns [Ok "${token}"] but still
    looks up the relevant config file as it would normally have. *)

val keep_v : keep_v:bool Cli.t -> (bool, Bos_setup.R.msg) result

val auto_open : no_auto_open:bool Cli.t -> (bool, Bos_setup.R.msg) result

val opam_repo_fork :
  ?pkgs:Pkg.t list ->
  remote:string Cli.t option ->
  local:Fpath.t Cli.t option ->
  unit ->
  (Opam_repo_fork.t, Bos_setup.R.msg) result
(** Returns the opam-repository fork to use, based on the CLI provided values
    [remote] and [local] and the user's configuration.

    If both [remote] and [local] are provided, they are returned without reading
    any local configuration.

    If either or both of them are [None], the configuration is looked up. If it
    doesn't exist, the interactive creation quizz is started. The configuration
    values are used to fill up the blanks in [remote] and [local].

    [pkgs] is only used to offer suggestions to the user during the creation
    quizz. *)

val load : unit -> (t option, Bos_setup.R.msg) result

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
    string ->
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
    (string, Bos_setup.R.msg) result

  val unset :
    dry_run:bool ->
    build_dir:Fpath.t ->
    name:string ->
    version:string ->
    (unit, Bos_setup.R.msg) result
end

module Draft_release : S

module Draft_pr : S

module Release_asset_name : S
