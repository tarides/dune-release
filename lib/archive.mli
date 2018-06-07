(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

(** Archive creation. *)

open Bos_setup

(** {1 Ustar archives} *)

val tar :
  Fpath.t -> exclude_paths:Fpath.set -> root:Fpath.t -> mtime:int ->
  (string, R.msg) result
(** [tar dir ~exclude_paths ~root ~mtime] is a (us)tar archive that
    contains the file hierarchy [dir] except the relative hierarchies
    present in [exclude_paths]. In the archive, members of [dir] are
    rerooted at [root] and sorted according to {!Fpath.compare}. They
    have their modification time set to [mtime] and their file
    permissions are [0o775] for directories and files executable by the
    user and [0o664] for other files. No other file metadata is
    preserved.

    {b Note.} This is a pure OCaml implementation, no [tar] tool is
    needed. *)

(** {1 Bzip2 compression and unarchiving} *)

val ensure_bzip2 : unit -> (unit, R.msg) result
(** [ensure_bzip2 ()] makes sure the [bzip2] utility is available. *)

val bzip2 : dry_run:bool -> ?force:bool ->
  dst:Fpath.t -> string -> (unit, R.msg) result
(** [bzip2 dst s] compresses [s] to [dst] using bzip2. *)

val ensure_tar : unit -> (unit, R.msg) result
(** [ensure_tar ()] makes sure the [tar] utility is available. *)

val untbz : dry_run:bool -> ?clean:bool -> Fpath.t -> (Fpath.t, R.msg) result
(** [untbz ~clean ar] untars the tar bzip2 archive [ar] in the same
    directory as [ar] and returns a base directory for [ar]. If [clean]
    is [true] (defaults to [false]) first delete the base directory if
    it exists. *)

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
