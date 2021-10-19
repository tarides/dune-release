(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

(** VCS repositories. *)

(** {1 VCS} *)

open Rresult

(** {1:vcsops Version control system repositories} *)

module Tag : sig
  type t

  val pp : t Fmt.t

  val equal : t -> t -> bool
  (** [equal a b] returns [true] if [a] and [b] are the same tag. No check
      whether these commits point to the same data is done. *)

  val to_string : t -> string
  (** [to_string v] returns the [string] representation of the tag. *)

  val of_string : string -> t
  (** [of_string v] reads the specified [v] without any validation. This should
      be done only in rare cases, for most usages it is better to derive a
      [Tag.t] from a [Version.t] via [Version.to_tag]. *)
end

type commit_ish = string
(** The type for symbols resolving to a commit. The module uses ["HEAD"] for
    specifying the current checkout; use this symbol even if the underlying VCS
    is [`Hg]. *)

module Tag_or_commit_ish : sig
  type t = Tag of Tag.t | Commit_ish of commit_ish
end

type t
(** The type for version control systems repositories. *)

val cmd : t -> Bos.Cmd.t
(** [cmd r] is the base VCS command to use to act on [r].

    {b Warning} Prefer the functions below to remain VCS independent. *)

val get : ?dir:Fpath.t -> unit -> (t, R.msg) result
(** [get ~dir ()] looks for a VCS repository in working directory [dir] (not the
    repository directory like [.git], default is guessed automatically). Returns
    an error if no VCS was found. *)

val run_git_quiet :
  dry_run:bool -> ?force:bool -> t -> Bos_setup.Cmd.t -> (unit, R.msg) result

val run_git_string :
  dry_run:bool ->
  ?force:bool ->
  default:string * Bos.OS.Cmd.run_status ->
  t ->
  Bos_setup.Cmd.t ->
  (string, R.msg) result

(** {1:state Repository state} *)

val is_dirty : t -> (bool, R.msg) result
(** [is_dirty r] is [Ok true] iff the working tree of [r] has uncommited
    changes. *)

val commit_id :
  ?dirty:bool -> ?commit_ish:commit_ish -> t -> (commit_ish, R.msg) result
(** [commit_id ~dirty ~commit_ish r] is the object name (identifier) of
    [commit_ish] (defaults to ["HEAD"]). If [commit_ish] is ["HEAD"] and [dirty]
    is [true] (default) an indicator is appended to the identifier if the
    working tree is dirty. *)

val commit_ptime_s :
  dry_run:bool -> ?commit_ish:Tag_or_commit_ish.t -> t -> (int64, R.msg) result
(** [commit_ptime_s t ~commit_ish] is the POSIX time in seconds of commit
    [commit_ish] (defaults to ["HEAD"]) of repository [r]. *)

val describe :
  ?dirty:bool -> ?commit_ish:commit_ish -> t -> (string, R.msg) result
(** [describe ~dirty ~commit_ish r] identifies [commit_ish] (defaults to
    ["HEAD"]) using tags from the repository [r]. If [commit_ish] is ["HEAD"]
    and [dirty] is [true] (default) an indicator is appended to the identifier
    if the working tree is dirty. *)

val get_tag : t -> (Tag.t, R.msg) result
val tag_exists : dry_run:bool -> t -> Tag.t -> bool
val tag_points_to : t -> Tag.t -> string option
val branch_exists : dry_run:bool -> t -> commit_ish -> bool

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
  ?branch:commit_ish ->
  t ->
  commit_ish:Tag_or_commit_ish.t ->
  (unit, R.msg) result
(** [checkout r ~branch commit_ish] checks out [commit_ish]. Checks out in a new
    branch [branch] if provided. *)

val change_branch : dry_run:bool -> branch:string -> t -> (unit, R.msg) result
(** [change_branch ~branch r] moves the head to an existing branch [branch]. *)

val tag :
  dry_run:bool ->
  ?force:bool ->
  ?sign:bool ->
  ?msg:string ->
  ?commit_ish:string ->
  t ->
  Tag.t ->
  (unit, R.msg) result
(** [tag r ~force ~sign ~msg ~commit_ish t] tags [commit_ish] with [t] and
    message [msg] (if unspecified the VCS should prompt). if [sign] is [true]
    (defaults to [false]) signs the tag ([`Git] repos only). If [force] is
    [true] (default to [false]) doesn't fail if the tag already exists. *)

val delete_tag : dry_run:bool -> t -> Tag.t -> (unit, R.msg) result
(** [delete_tag r t] deletes tag [t] in repo [r]. *)

val ls_remote :
  dry_run:bool ->
  t ->
  ?kind:[ `Branch | `Tag | `All ] ->
  ?filter:string ->
  string ->
  ((string * string) list, R.msg) result
(** [ls_remote ~dry_run t ?filter upstream] queries the remote server [upstream]
    and returns the result as a list of pairs [commit_hash, ref_name]. [filter]
    filters results by matching on ref names, the default is no filtering.
    [kind] filters results on their kind (branch or tag), the default is [`All].
    Only implemented for Git. *)

val submodule_update : dry_run:bool -> t -> (unit, R.msg) result
(** [submodule r] pulls in all submodules in [r]. Only works for git
    repositories *)

val git_escape_tag : string -> Tag.t
(** Exposed for tests. *)

val escape_tag : t -> string -> Tag.t

val git_unescape_tag : Tag.t -> string
(** Exposed for tests. *)

val unescape_tag : t -> Tag.t -> string

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
