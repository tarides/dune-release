(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup.R.Infix

(* Only carry on when the first operation returns 0 *)
let ( >! ) x f = match x with Ok 0 -> f () | _ -> x

let bistro () (`Dry_run dry_run) (`Package_names pkg_names)
    (`Package_version version) (`Dist_tag tag) (`Keep_v keep_v) (`Token token)
    (`Include_submodules include_submodules) (`Draft draft)
    (`Keep_build_dir keep_dir) (`Skip_lint skip_lint) (`Skip_build skip_build)
    (`Skip_tests skip_tests) (`Local_repo local_repo) (`Remote_repo remote_repo)
    (`Opam_repo opam_repo) (`No_auto_open no_auto_open) (`Dev_repo dev_repo) =
  Cli.handle_error
    ( Dune_release.Config.token ~token ~dry_run () >>= fun token ->
      let token = Dune_release.Config.Cli.make token in
      Distrib.distrib ~dry_run ~pkg_names ~version ~tag ~keep_v ~keep_dir
        ~skip_lint ~skip_build ~skip_tests ~include_submodules ()
      >! fun () ->
      Publish.publish ~token ~version ~tag ~keep_v ~dry_run ?dev_repo ~yes:false
        ~draft ()
      >! fun () ->
      Opam.get_pkgs ~dry_run ~keep_v ~tag ~pkg_names ~version () >>= fun pkgs ->
      Opam.pkg ~dry_run ~pkgs () >! fun () ->
      Opam.submit ~token ~dry_run ~pkgs ~pkg_names ~no_auto_open ~yes:false
        ~draft () ?local_repo ?remote_repo ?opam_repo )

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
       dune-release publish       # Publish it to Github with its documentation\n\
       dune-release opam pkg      # Create an opam package\n\
       dune-release opam submit   # Submit it to OCaml's opam repository";
    `P "See dune-release(7) for more information.";
  ]

let term =
  Term.(
    const bistro $ Cli.setup $ Cli.dry_run $ Cli.pkg_names $ Cli.pkg_version
    $ Cli.dist_tag $ Cli.keep_v $ Cli.token $ Cli.include_submodules $ Cli.draft
    $ Cli.keep_build_dir $ Cli.skip_lint $ Cli.skip_build $ Cli.skip_tests
    $ Cli.local_repo $ Cli.remote_repo $ Cli.opam_repo $ Cli.no_auto_open
    $ Cli.dev_repo)

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
