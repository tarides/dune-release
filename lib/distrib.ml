(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Rresult

(* Defaults *)

let default_exclude_paths () =
  let l =
    List.map Fpath.v
      [
        ".git";
        ".gitignore";
        ".gitattributes";
        ".hg";
        ".hgignore";
        "build";
        "_build";
      ]
  in
  Ok l

(* Distribution *)

type t = {
  massage : unit -> (unit, R.msg) result;
  exclude_paths : unit -> (Fpath.t list, R.msg) result;
}

let v ?(massage = fun () -> Ok ()) ?(exclude_paths = default_exclude_paths) () =
  { massage; exclude_paths }

let massage d = d.massage

let exclude_paths d = d.exclude_paths

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
