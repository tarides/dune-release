(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

(** VCS repositories. *)

(** {1 VCS} *)

open Rresult

(** {1:vcsops Version control system repositories} *)

type commit_ish = string
(** The type for symbols resolving to a commit. The module uses ["HEAD"] for
    specifying the current checkout; use this symbol even if the underlying VCS
    is [`Hg]. *)

type t
(** The type for version control systems repositories. *)

val cmd : t -> Bos.Cmd.t
(** [cmd r] is the base VCS command to use to act on [r].

    {b Warning} Prefer the functions below to remain VCS independent. *)

val cmd_error : Bos.Cmd.t -> Bos.OS.Cmd.status -> ('a, R.msg) result
(** [cmd_error cmd status] returns an error message describing the failing
    command [cmd] and the exit status [status]. *)

val get : ?dir:Fpath.t -> unit -> (t, R.msg) result
(** [get] is like {!find} but returns an error if no VCS was found. *)

(** {1:state Repository state} *)

val is_dirty : t -> (bool, R.msg) result
(** [is_dirty r] is [Ok true] iff the working tree of [r] has uncommited
    changes. *)

val commit_id :
  ?dirty:bool -> ?commit_ish:commit_ish -> t -> (string, R.msg) result
(** [commit_id ~dirty ~commit_ish r] is the object name (identifier) of
    [commit_ish] (defaults to ["HEAD"]). If [commit_ish] is ["HEAD"] and [dirty]
    is [true] (default) and indicator is appended to the identifier if the
    working tree is dirty. *)

val commit_ptime_s :
  dry_run:bool -> ?commit_ish:commit_ish -> t -> (int, R.msg) result
(** [commit_ptime_s t ~commit_ish] is the POSIX time in seconds of commit
    [commit_ish] (defaults to ["HEAD"]) of repository [r]. *)

val describe :
  ?dirty:bool -> ?commit_ish:commit_ish -> t -> (string, R.msg) result
(** [describe ~dirty ~commit_ish r] identifies [commit_ish] (defaults to
    ["HEAD"]) using tags from the repository [r]. If [commit_ish] is ["HEAD"]
    and [dirty] is [true] (default) an indicator is appended to the identifier
    if the working tree is dirty. *)

val tag_exists : dry_run:bool -> t -> string -> bool

val tag_points_to : t -> tag:string -> string option

val branch_exists : dry_run:bool -> t -> string -> bool

(** {1:ops Repository operations} *)

val clone :
  dry_run:bool ->
  ?force:bool ->
  ?branch:string ->
  dir:Fpath.t ->
  t ->
  (unit, R.msg) result
(** [clone ~dir r] clones [r] in directory [dir]. *)

val checkout :
  dry_run:bool ->
  ?branch:string ->
  t ->
  commit_ish:commit_ish ->
  (unit, R.msg) result
(** [checkout r ~branch commit_ish] checks out [commit_ish]. Checks out in a new
    branch [branch] if provided. *)

val tag :
  dry_run:bool ->
  ?force:bool ->
  ?sign:bool ->
  ?msg:string ->
  ?commit_ish:string ->
  t ->
  string ->
  (unit, R.msg) result
(** [tag r ~force ~sign ~msg ~commit_ish t] tags [commit_ish] with [t] and
    message [msg] (if unspecified the VCS should prompt). if [sign] is [true]
    (defaults to [false]) signs the tag ([`Git] repos only). If [force] is
    [true] (default to [false]) doesn't fail if the tag already exists. *)

val delete_tag : dry_run:bool -> t -> string -> (unit, R.msg) result
(** [delete_tag r t] deletes tag [t] in repo [r]. *)

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
