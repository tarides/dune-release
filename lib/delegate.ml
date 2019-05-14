(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup

(* Running the delegate *)
let run_delegate ~dry_run del args =
  let verbosity = Logs.level_to_string (Logs.level ()) in
  Ok Cmd.(del % "ipc" % verbosity %% args)
  >>= fun cmd -> Sos.run_status ~dry_run cmd
  >>= function
  | `Exited 0 -> Ok ()
  | `Exited 1 -> R.error_msgf "Action unsupported by delegate %a" Cmd.pp del
  | (`Exited n | `Signaled n) ->
      R.error_msgf "Delegate %a errored with %d" Cmd.pp del n

(* Publish request *)

let publish_distrib ~dry_run ~msg ~archive p =
  Pkg.delegate p >>= function
  | None     ->
      Logs.app (fun l -> l "Publishing to github");
      Github.publish_distrib ~dry_run ~msg ~archive p
  | Some del ->
      Logs.app (fun l -> l "Using delegate %a" Cmd.pp del);
      Pkg.name p
      >>= fun name -> Pkg.tag p
      >>= fun version -> Pkg.distrib_uri p
      >>= fun distrib_uri ->
      run_delegate ~dry_run del
        Cmd.(v "publish" % "distrib" % distrib_uri %
             name % version % msg % p archive)

let publish_doc ~dry_run ~msg ~docdir p =
  Pkg.delegate p >>= function
  | None     ->
      Logs.app (fun l -> l "Publishing to github");
      Github.publish_doc ~dry_run ~msg ~docdir p
  | Some del ->
      Logs.app (fun l -> l "Using delegate %a" Cmd.pp del);
      let doc_uri p = Pkg.opam_field_hd p "doc" >>= function
        | None -> Ok ""
        | Some uri -> Ok uri
      in
      Pkg.name p
      >>= fun name -> Pkg.version p
      >>= fun version -> doc_uri p
      >>= fun doc_uri ->
      run_delegate ~dry_run del
        Cmd.(v "publish" % "doc" % doc_uri % name % version % msg %
             p docdir)

let publish_alt ~dry_run ~kind ~msg ~archive p =
  Pkg.delegate p >>= function
  | None     -> R.error_msgf "No default delegate to publish %s" kind
  | Some del ->
      Logs.app (fun l -> l "Using delegate %a" Cmd.pp del);
      Pkg.name p
      >>= fun name -> Pkg.version p
      >>= fun version -> Pkg.distrib_uri p
      >>= fun distrib_uri ->
      run_delegate ~dry_run del
        Cmd.(v "publish" % "alt" % distrib_uri % kind %
             name % version % msg % p archive)

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
