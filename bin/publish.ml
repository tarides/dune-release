(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup
open Dune_release

let gen_doc ~dry_run ~force dir pkg_names =
  let names = String.concat ~sep:"," pkg_names in
  let build_doc = Cmd.(v "dune" % "build" % "-p" % names % "@doc") in
  let doc_dir = Fpath.(v "_build" / "default" / "_doc" / "_html") in
  let do_doc () = Sos.run ~dry_run ~force build_doc in
  R.join @@ Sos.with_dir ~dry_run dir do_doc () >>= fun () ->
  Ok Fpath.(dir // doc_dir)

let publish_doc ~dry_run ~yes pkg_names pkg =
  App_log.status (fun l -> l "Publishing documentation");
  Pkg.distrib_file ~dry_run pkg
  >>= fun archive -> Pkg.publish_msg pkg
  >>= fun msg -> Archive.untbz ~dry_run ~clean:true archive
  >>= fun dir -> OS.Dir.exists dir
  >>= fun force -> Pkg.infer_pkg_names dir pkg_names
  >>= fun pkg_names ->
  App_log.status (fun l -> l "Selected packages: %a"
                     Fmt.(list ~sep:(unit "@ ") (styled `Bold string))
                     pkg_names);
  App_log.status (fun l -> l "Generating documentation from %a" Text.Pp.path archive);
  gen_doc ~dry_run ~force dir pkg_names
  >>= fun docdir ->
  App_log.status (fun l -> l "Publishing to github");
  Github.publish_doc ~dry_run ~msg ~docdir ~yes pkg

let publish_distrib ~dry_run ~yes pkg =
  App_log.status (fun l -> l "Publishing distribution");
  Pkg.distrib_file ~dry_run pkg >>= fun archive ->
  Pkg.publish_msg pkg >>= fun msg ->
  App_log.status (fun l -> l "Publishing to github");
  Github.publish_distrib ~dry_run ~yes ~msg ~archive pkg >>= fun url ->
  Pkg.archive_url_path pkg >>= fun url_file ->
  Sos.write_file ~dry_run url_file url

let publish ()
    build_dir name pkg_names version tag keep_v opam change_log
    distrib_uri distrib_file publish_msg dry_run publish_artefacts yes
  =
  begin
    let publish_artefacts = match publish_artefacts with
    | [] -> None
    | v  -> Some v
    in
    Config.keep_v keep_v >>= fun keep_v ->
    let pkg =
      Pkg.v ~dry_run ?name ?version ?tag ~keep_v ?build_dir ?opam
        ?change_log ?distrib_uri ?distrib_file ?publish_msg
        ?publish_artefacts ()
    in
    let publish_artefact acc artefact =
      acc >>= fun () -> match artefact with
      | `Doc      -> publish_doc ~dry_run ~yes pkg_names pkg
      | `Distrib  -> publish_distrib ~dry_run ~yes pkg
    in
    Pkg.publish_artefacts pkg
    >>= fun todo -> List.fold_left publish_artefact (Ok ()) todo
    >>= fun () -> Ok 0
  end
  |> Cli.handle_error

(* Command line interface *)

open Cmdliner

let artefacts =
  let parser = function
  | "do" | "doc" -> `Ok `Doc
  | "di" | "dis" | "dist" | "distr" | "distri" | "distrib" -> `Ok `Distrib
  | s -> `Error (strf "`%s' unknown publication artefact" s)
  in
  let printer ppf = function
  | `Doc     -> Fmt.string ppf "doc"
  | `Distrib -> Fmt.string ppf "distrib"
  in
  let artefact = parser, printer in
  let doc = strf "The artefact to publish. $(docv) must be either `doc` or
                  `distrib`. If absent, the set of
                  default publication artefacts is determined by the
                  package description."
  in
  Arg.(value & pos_all artefact [] & info [] ~doc ~docv:"ARTEFACT")

let doc = "Publish package distribution archives and derived artefacts"
let sdocs = Manpage.s_common_options
let exits = Cli.exits

let man_xrefs = [`Main; `Cmd "distrib" ]
let man =
  [ `S Manpage.s_synopsis;
    `P "$(mname) $(tname) [$(i,OPTION)]... [$(i,ARTEFACT)]...";
    `S Manpage.s_description;
    `P "The $(tname) command publishes package distribution archives
        and other artefacts.";
    `P "Artefact publication always relies on a distribution archive having
        been generated before with dune-release-distrib(1).";
    `S "ARTEFACTS";
    `I ("$(b,distrib)",
        "Publishes a distribution archive on the WWW.");
    `I ("$(b,doc)",
        "Publishes the documentation of a distribution archive on the WWW.");
  ]

let cmd =
  Term.(pure publish $ Cli.setup $ Cli.build_dir $
        Cli.dist_name $ Cli.pkg_names
        $ Cli.pkg_version $ Cli.dist_tag $ Cli.keep_v
        $ Cli.dist_opam $ Cli.change_log $ Cli.dist_uri $ Cli.dist_file $
        Cli.publish_msg $ Cli.dry_run $ artefacts $ Cli.yes),
  Term.info "publish" ~doc ~sdocs ~exits ~envs:[] ~man ~man_xrefs

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
