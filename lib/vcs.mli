(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

(** VCS repositories. *)

(** {1 VCS} *)

open Rresult

type kind = [ `Git | `Hg ]
val pp_kind : Format.formatter -> kind -> unit

type commit_ish = string

type t

val kind : t -> kind
val dir : t -> Fpath.t
val find : ?dir:Fpath.t -> unit -> (t option, R.msg) result
val get : ?dir:Fpath.t -> unit -> (t, R.msg) result
val cmd : t -> Bos.Cmd.t
val pp : Format.formatter -> t -> unit

val is_dirty : t -> (bool, R.msg) result
val not_dirty : t -> (unit, R.msg) result
val file_is_dirty : t -> Fpath.t -> (bool, R.msg) result
val head : ?dirty:bool -> t -> (string, R.msg) result
val commit_id : ?dirty:bool -> ?commit_ish:string -> t -> (string, R.msg) result
val commit_ptime_s : ?commit_ish:commit_ish -> t -> (int, R.msg) result
val describe : ?dirty:bool -> ?commit_ish:string -> t -> (string, R.msg) result
val tags : t -> (string list, R.msg) result
val changes :
  ?until:string -> t -> after:string -> ((string * string) list, R.msg) result

val tracked_files : ?tree_ish:string -> t -> (Fpath.t list, R.msg) result

val clone : t -> dir:Fpath.t -> (unit, R.msg) result
val checkout : ?branch:string -> t -> commit_ish:string -> (unit, R.msg) result
val commit_files : ?msg:string -> t -> Fpath.t list -> (unit, R.msg) result

val delete_tag : t -> string -> (unit, R.msg) result
val tag :
  ?force:bool -> ?sign:bool -> ?msg:string -> ?commit_ish:string -> t ->
  string -> (unit, R.msg) result

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
