(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

(** Interface with Github. *)

open Bos_setup

module Parse : sig
  val user_from_remote : string -> string option
  (** [user_from_remote remote_uri] is the username in the github URI
      [remote_uri], ie:

      - [user_from_remote_uri "git@github.com:username/repo.git"] returns
        [Some "username"]
      - [user_from_remote_uri "https://github.com/username/repo.git"] returns
        [Some "username"].
      - Returns [None] if [remote_uri] isn't in the expected format. *)
end

(** {1 Publish} *)

val publish_distrib :
  ?token:Fpath.t ->
  dry_run:bool ->
  msg:string ->
  archive:Fpath.t ->
  yes:bool ->
  Pkg.t ->
  (string, R.msg) Result.result
(** Push the tag, create a Github release, upload the distribution archive and
    return the release archive download URL *)

val publish_doc :
  dry_run:bool ->
  msg:string ->
  docdir:Fpath.t ->
  yes:bool ->
  Pkg.t ->
  (unit, R.msg) Result.result

val open_pr :
  token:Fpath.t ->
  dry_run:bool ->
  title:string ->
  distrib_user:string ->
  user:string ->
  branch:string ->
  opam_repo:string * string ->
  string ->
  ([ `Url of string | `Already_exists ], R.msg) result

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
