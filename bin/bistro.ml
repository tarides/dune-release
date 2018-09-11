(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup

let add args name v = match v with
| None   -> args
| Some x -> Cmd.(args % name % x)

let add_l args name v = match v with
| [] -> args
| x  -> Cmd.(args % name % String.concat ~sep:"," x)

let bistro () dry_run name pkg_names version tag keep_v =
  begin
    let args = Cmd.(v "--verbosity" % Logs.(level_to_string (level ()))) in
    let args = if dry_run then Cmd.(args % "--dry-run") else args in
    let args = add args "--name" name in
    let args = add args "--pkg-version" version in
    let args = if keep_v then Cmd.(args % "--keep-v") else args in
    let args = add args "--tag" tag in
    let args = add_l args "--pkg-names" pkg_names in
    let dune_release = Cmd.(v "dune-release") in
    OS.Cmd.run Cmd.(dune_release % "distrib" %% args)
    >>= fun () -> OS.Cmd.run Cmd.(dune_release % "publish" %% args)
    >>= fun () -> OS.Cmd.run Cmd.(dune_release % "opam" %% args % "pkg")
    >>= fun () -> OS.Cmd.run Cmd.(dune_release % "opam" %% args % "submit")
    >>= fun () -> Ok 0
  end
  |> Cli.handle_error

(* Command line interface *)

open Cmdliner

let doc = "For when you are in a hurry or need to go for a drink"
let sdocs = Manpage.s_common_options
let exits = Cli.exits
let man_xrefs = [ `Main; `Cmd "distrib"; `Cmd "publish"; `Cmd "opam" ]
let man =
  [ `S Manpage.s_description;
    `P "The $(tname) command (quick in Russian) is equivalent to invoke:";
    `Pre "\
dune-release distrib       # Create the distribution archive
dune-release publish       # Publish it on the WWW with its documentation
dune-release opam pkg      # Create an opam package
dune-release opam submit   # Submit it to OCaml's opam repository";
    `P "See dune-release(7) for more information."; ]

let cmd =
  Term.(pure bistro $ Cli.setup $ Cli.dry_run
        $ Cli.dist_name $ Cli.pkg_names
        $ Cli.pkg_version $ Cli.dist_tag $ Cli.keep_v),
  Term.info "bistro" ~doc ~sdocs ~exits ~man ~man_xrefs

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
