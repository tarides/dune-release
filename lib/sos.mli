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

(** Safe OS operations.

   All the commands in that module can have side-effects. They also
   all take a [--dry-run] paramater which cause the side-effect to be
   discarded and to display a message instead. Some of these commands
   also have a `[--force]` option: this causes the message to be
   printed AND the side-effects to be caused.  *)

type error = Bos_setup.R.msg

val run :
  dry_run:bool ->
  ?force:bool ->
  ?sandbox:bool ->
  Bos.Cmd.t ->
  (unit, error) result

val run_quiet :
  dry_run:bool ->
  ?force:bool ->
  ?sandbox:bool ->
  Bos.Cmd.t ->
  (unit, error) result
(** Same as run but redirects err and out to null *)

val run_io :
  dry_run:bool ->
  ?force:bool ->
  ?sandbox:bool ->
  default:'a ->
  Bos.Cmd.t ->
  Bos.OS.Cmd.run_in ->
  (Bos.OS.Cmd.run_out -> ('a, 'b) result) ->
  ('a, 'b) result

val run_out :
  dry_run:bool ->
  ?force:bool ->
  ?sandbox:bool ->
  ?err:Bos.OS.Cmd.run_err ->
  default:'a ->
  Bos.Cmd.t ->
  (Bos.OS.Cmd.run_out -> ('a, 'b) result) ->
  ('a, 'b) result

val run_status :
  dry_run:bool ->
  ?force:bool ->
  ?sandbox:bool ->
  Bos.Cmd.t ->
  (Bos.OS.Cmd.status, error) result

val delete_dir : dry_run:bool -> ?force:bool -> Fpath.t -> (unit, error) result

val delete_path : dry_run:bool -> Fpath.t -> (unit, error) result

val read_file : dry_run:bool -> Fpath.t -> (string, error) result

val write_file :
  dry_run:bool -> ?force:bool -> Fpath.t -> string -> (unit, error) result

val with_dir : dry_run:bool -> Fpath.t -> ('a -> 'b) -> 'a -> ('b, error) result

val file_exists : dry_run:bool -> Fpath.t -> (bool, error) result

val dir_exists : dry_run:bool -> Fpath.t -> (bool, error) result

val file_must_exist : dry_run:bool -> Fpath.t -> (Fpath.t, error) result

val out : 'a -> 'a * Bos.OS.Cmd.run_status

val mkdir : dry_run:bool -> Fpath.t -> (bool, error) result

val cp :
  dry_run:bool ->
  rec_:bool ->
  force:bool ->
  src:Fpath.t ->
  dst:Fpath.t ->
  (unit, error) result
(** [cp ~dry_run ~rec ~force ~src ~dst] copies [src] to [dst]. If [rec] is true, copies directories
    recursively. If [force] is true, overwrite existing files. The usual [force] arguments from
    other functions in this module is renamed [force_side_effects] here. *)

val relativize : src:Fpath.t -> dst:Fpath.t -> (Fpath.t, error) result
(** [relativize ~src ~dst] return a relative path from [src] to [dst]. If such a path can't be
    expressed, i.e. [srs] and [dst] don't have a common root, returns an error. *)
