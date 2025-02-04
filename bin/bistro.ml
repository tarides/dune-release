(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup.R.Infix

(* Only carry on when the first operation returns 0 *)
let ( >! ) x f = match x with Ok 0 -> f () | _ -> x

(* Command line interface *)

open Cmdliner

let doc = "For when you are in a hurry or need to go for a drink"
let sdocs = Manpage.s_common_options
let exits = Cli.exits
let man_xrefs = [ `Main; `Cmd "distrib"; `Cmd "publish"; `Cmd "opam" ]

let man =
  [
    `S Manpage.s_description;
    `P "The $(tname) command (quick in Russian) is equivalent to invoke:";
    `Pre
      "dune-release distrib       # Create the distribution archive\n\
       dune-release publish       # Publish it to Github\n\
       dune-release opam pkg      # Create an opam package\n\
       dune-release opam submit   # Submit it to OCaml's opam repository";
    `P "See dune-release(7) for more information.";
  ]

let term =
  Term.(
    let open Syntax in
    let+ () = Cli.setup
    and+ (`Dry_run dry_run) = Cli.dry_run
    and+ (`Package_names pkg_names) = Cli.pkg_names
    and+ (`Package_version version) = Cli.pkg_version
    and+ (`Dist_tag tag) = Cli.dist_tag
    and+ (`Keep_v keep_v) = Cli.keep_v
    and+ (`Token token) = Cli.token
    and+ (`Include_submodules include_submodules) = Cli.include_submodules
    and+ (`Draft draft) = Cli.draft
    and+ (`Keep_build_dir keep_dir) = Cli.keep_build_dir
    and+ (`Skip_lint skip_lint) = Cli.skip_lint
    and+ (`Skip_build skip_build) = Cli.skip_build
    and+ (`Skip_tests skip_tests) = Cli.skip_tests
    and+ (`Local_repo local_repo) = Cli.local_repo
    and+ (`Remote_repo remote_repo) = Cli.remote_repo
    and+ (`Opam_repo opam_repo) = Cli.opam_repo
    and+ (`No_auto_open no_auto_open) = Cli.no_auto_open
    and+ (`Dev_repo dev_repo) = Cli.dev_repo in
    Cli.handle_error
      ( Dune_release.Config.token ~token ~dry_run () >>= fun token ->
        let token = Dune_release.Config.Cli.make token in
        Distrib.distrib ~dry_run ~pkg_names ~version ~tag ~keep_v ~keep_dir
          ~skip_lint ~skip_build ~skip_tests ~include_submodules ()
        >! fun () ->
        Publish.publish ~token ~version ~tag ~keep_v ~dry_run ?dev_repo
          ~yes:false ~draft ()
        >! fun () ->
        Opam.get_pkgs ~dry_run ~keep_v ~tag ~pkg_names ~version ()
        >>= fun pkgs ->
        Opam.pkg ~dry_run ~pkgs () >! fun () ->
        Opam.submit ~token ~dry_run ~pkgs ~pkg_names ~no_auto_open ~yes:false
          ~draft () ?local_repo ?remote_repo ?opam_repo ))

let info = Cmd.info "bistro" ~doc ~sdocs ~exits ~man ~man_xrefs
let cmd = Cmd.v info term

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
