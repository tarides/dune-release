(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

(** {1 Distribution description} *)

open Rresult

(** {1:distrib Distribution description} *)

type t
(** The type for describing distribution creation. *)

val v :
  ?massage:(unit -> (unit, R.msg) result) ->
  ?exclude_paths:(unit -> (Fpath.t list, R.msg) result) ->
  unit ->
  t
(** [distrib ~massage ~exclude_paths ()] influences the distribution creation
    process performed by the [dune-release] tool. See the {{!distdetails} full
    details about distribution creation}.

    In the following the {e distribution build directory} is a private clone of
    the package's source repository's [HEAD] when [dune-release distrib] is
    invoked.

    - [massage] is invoked in the distribution build directory, before
      archiving. It can be used to generate distribution time build artefacts.
      Defaults to {!massage}.
    - [exclude_paths ()] is invoked in the distribution build directory, after
      massaging, to determine the paths that are excluded from being added to
      the distribution archive. Defaults to {!exclude_paths}. *)

val default_massage : unit -> (unit, R.msg) result
(** [default_massage] is the default distribution massaging function. It is
    invoked in the distribution build directory and does nothing. *)

val default_exclude_paths : unit -> (Fpath.t list, R.msg) result
(** [default_exclude_paths ()] is the default list of paths to exclude from the
    distribution archive. It is invoked in the distribution build directory and
    returns the following static set of files.

    {[
      fun () ->
        Ok
          [
            ".git";
            ".gitignore";
            ".gitattributes";
            ".hg";
            ".hgignore";
            "build";
            "Makefile";
            "_build";
          ]
    ]} *)

val massage : t -> unit -> (unit, R.msg) result

val exclude_paths : t -> unit -> (Fpath.t list, R.msg) result

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
