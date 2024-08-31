(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup.R.Infix
open Cmdliner

let cmds =
  [
    Tag.cmd;
    Distrib.cmd;
    Publish.cmd;
    Opam.cmd;
    Help.cmd;
    Lint.cmd;
    Check.cmd;
    Delegate_info.cmd;
    Config.cmd;
    Undraft.cmd;
  ]

(* Command line interface *)

let doc = "Release dune packages to opam"
let sdocs = Manpage.s_common_options
let exits = Cli.exits

let man =
  [
    `S Manpage.s_description;
    `P "$(mname) releases dune packages to opam.";
    `P "The $(mname) command is equivalent to the invokation of:";
    `Pre
      "dune-release distrib       # Create the distribution archive\n\
       dune-release publish       # Publish it on the WWW with its documentation\n\
       dune-release opam pkg      # Create an opam package\n\
       dune-release opam submit   # Submit it to OCaml's opam repository";
    `P "See dune-release(7) for more information.";
    `P "Use '$(mname) help release' for help to release a package.";
    `Noblank;
    `P "Use '$(mname) help troubleshoot' for a few troubleshooting tips.";
    `Noblank;
    `P "Use '$(mname) help $(i,COMMAND)' for help about $(i,COMMAND).";
    `S Manpage.s_bugs;
    `P "Report them, see $(i,%%PKG_HOMEPAGE%%) for contact information.";
    `S Manpage.s_authors;
    `P "Daniel C. Buenzli, $(i,http://erratique.ch)";
  ]

(* Only carry on when the first operation returns 0 *)
let ( >! ) x f = match x with Ok 0 -> f () | _ -> x

let auto () (`Dry_run dry_run) (`Package_names pkg_names)
    (`Package_version version) (`Dist_tag tag) (`Keep_v keep_v) (`Token token)
    (`Include_submodules include_submodules) (`Draft draft)
    (`Local_repo local_repo) (`Remote_repo remote_repo) (`Opam_repo opam_repo)
    (`No_auto_open no_auto_open) =
  Cli.handle_error
    ( Dune_release.Config.token ~token ~dry_run () >>= fun token ->
      let token = Dune_release.Config.Cli.make token in
      Distrib.distrib ~dry_run ~pkg_names ~version ~tag ~keep_v ~keep_dir:false
        ~skip_lint:false ~skip_build:false ~skip_tests:false ~include_submodules
        ()
      >! fun () ->
      Publish.publish ~token ~pkg_names ~version ~tag ~keep_v ~dry_run
        ~publish_artefacts:[] ~yes:false ~draft ()
      >! fun () ->
      Opam.get_pkgs ~dry_run ~keep_v ~tag ~pkg_names ~version () >>= fun pkgs ->
      Opam.pkg ~dry_run ~pkgs () >! fun () ->
      Opam.submit ~token ~dry_run ~pkgs ~pkg_names ~no_auto_open ~yes:false
        ~draft () ?local_repo ?remote_repo ?opam_repo )

let term =
  Term.(
    const auto $ Cli.setup $ Cli.dry_run $ Cli.pkg_names $ Cli.pkg_version
    $ Cli.dist_tag $ Cli.keep_v $ Cli.token $ Cli.include_submodules $ Cli.draft
    $ Cli.local_repo $ Cli.remote_repo $ Cli.opam_repo $ Cli.no_auto_open)

let main =
  Cmd.group ~default:term
    (Cmd.info "dune-release" ~version:"%%VERSION%%" ~doc ~sdocs ~exits ~man)
    cmds

let main () = Stdlib.exit @@ Cmd.eval' main
let () = main ()

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
