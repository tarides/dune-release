(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup
open Dune_release

let publish_distrib ?token ~dry_run ~yes ~draft ?dev_repo pkg =
  App_log.status (fun l -> l "Publishing distribution");
  Pkg.distrib_file ~dry_run pkg >>= fun archive ->
  Pkg.publish_msg pkg >>= fun msg ->
  App_log.status (fun l -> l "Publishing to github");
  Config.token ~token ~dry_run () >>= fun token ->
  Github.publish_distrib ~token ~dry_run ~yes ~msg ~archive ~draft ?dev_repo pkg
  >>= fun url ->
  Pkg.archive_url_path pkg >>= fun url_file ->
  Sos.write_file ~dry_run url_file url >>= fun () -> Ok ()

let publish ?build_dir ?opam ?change_log ?distrib_file ?publish_msg ?token
    ?dev_repo ~version ~tag ~keep_v ~dry_run ~yes ~draft () =
  Config.keep_v ~keep_v >>= fun keep_v ->
  let pkg =
    Pkg.v ~dry_run ?version ?tag ~keep_v ?build_dir ?opam ?change_log
      ?distrib_file ?publish_msg ()
  in
  publish_distrib ?token ~dry_run ~yes ~draft ?dev_repo pkg >>= fun () -> Ok 0

(* Command line interface *)

open Cmdliner

let doc = "Publish package distribution archives and/or documentation."
let sdocs = Manpage.s_common_options
let exits = Cli.exits
let man_xrefs = [ `Main; `Cmd "distrib" ]

let man =
  [
    `S Manpage.s_synopsis;
    `P "$(mname) $(tname) [$(i,OPTION)]...";
    `S Manpage.s_description;
    `P "The $(tname) command publishes package distribution archives.";
    `P
      "Artefact publication always relies on a distribution archive having \
       been generated before with dune-release-distrib(1).";
  ]

let term =
  Term.(
    let open Syntax in
    let+ () = Cli.setup
    and+ (`Build_dir build_dir) = Cli.build_dir
    and+ (`Package_version version) = Cli.pkg_version
    and+ (`Dist_tag tag) = Cli.dist_tag
    and+ (`Keep_v keep_v) = Cli.keep_v
    and+ (`Dist_opam opam) = Cli.dist_opam
    and+ (`Change_log change_log) = Cli.change_log
    and+ (`Dist_file distrib_file) = Cli.dist_file
    and+ (`Publish_msg publish_msg) = Cli.publish_msg
    and+ (`Dry_run dry_run) = Cli.dry_run
    and+ (`Yes yes) = Cli.yes
    and+ (`Token token) = Cli.token
    and+ (`Draft draft) = Cli.draft
    and+ (`Dev_repo dev_repo) = Cli.dev_repo in
    publish ?build_dir ?opam ?change_log ?distrib_file ?publish_msg ?token
      ~version ~tag ~keep_v ~dry_run ~yes ~draft ?dev_repo ()
    |> Cli.handle_error)

let info = Cmd.info "publish" ~doc ~sdocs ~exits ~man ~man_xrefs
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
