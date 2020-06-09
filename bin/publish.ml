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
  let doc_dir = Pkg.doc_dir in
  let do_doc () = Sos.run ~dry_run ~force build_doc in
  R.join @@ Sos.with_dir ~dry_run dir do_doc () >>= fun () ->
  Ok Fpath.(dir // doc_dir)

let publish_doc ~dry_run ~yes pkg_names pkg =
  Pkg.distrib_file ~dry_run pkg >>= fun archive ->
  Pkg.publish_msg pkg >>= fun msg ->
  Archive.untbz ~dry_run ~clean:true archive >>= fun dir ->
  OS.Dir.exists dir >>= fun force ->
  Pkg.infer_pkg_names dir pkg_names >>= fun pkg_names ->
  App_log.status (fun l ->
      l "Selected packages: %a"
        Fmt.(list ~sep:(unit "@ ") (styled `Bold string))
        pkg_names);
  App_log.status (fun l ->
      l "Generating documentation from %a" Text.Pp.path archive);
  gen_doc ~dry_run ~force dir pkg_names >>= fun docdir ->
  Delegate.publish_doc ~dry_run ~yes pkg ~msg ~docdir

(* If the `doc` field of the opam file is not set we do not generate nor
   publish the documentation, except when using a delegate. *)
let publish_doc ~dry_run ~yes pkg_names pkg =
  App_log.status (fun l -> l "Publishing documentation");
  match Pkg.doc_uri pkg with
  | Error _ | Ok "" -> (
      match Pkg.delegate pkg with
      | Ok (Some _) -> publish_doc ~dry_run ~yes pkg_names pkg
      | Error _ | Ok None ->
          Pkg.name pkg >>= fun name ->
          App_log.status (fun l -> l "No doc field found for package %s" name);
          App_log.status (fun l -> l "Skipping");
          Ok () )
  | Ok _ -> publish_doc ~dry_run ~yes pkg_names pkg

let publish_distrib ~dry_run ~yes pkg =
  App_log.status (fun l -> l "Publishing distribution");
  Pkg.distrib_file ~dry_run pkg >>= fun archive ->
  Pkg.publish_msg pkg >>= fun msg ->
  Delegate.publish_distrib ~dry_run ~yes pkg ~msg ~archive

let publish_alt ~dry_run pkg kind =
  App_log.status (fun l -> l "Publishing %s" kind);
  Pkg.distrib_file ~dry_run pkg >>= fun archive ->
  Pkg.publish_msg pkg >>= fun msg ->
  Delegate.publish_alt ~dry_run pkg ~kind ~msg ~archive

let publish ?build_dir ?opam ?delegate ?change_log ?distrib_uri ?distrib_file
    ?publish_msg ~name ~pkg_names ~version ~tag ~keep_v ~dry_run
    ~publish_artefacts ~yes () =
  let publish_artefacts =
    match publish_artefacts with [] -> None | v -> Some v
  in
  Config.keep_v keep_v >>= fun keep_v ->
  let pkg =
    Pkg.v ~dry_run ?name ?version ?tag ~keep_v ?build_dir ?opam ?change_log
      ?distrib_uri ?distrib_file ?publish_msg ?publish_artefacts ?delegate ()
  in
  let publish_artefact acc artefact =
    acc >>= fun () ->
    match artefact with
    | `Doc -> publish_doc ~dry_run ~yes pkg_names pkg
    | `Distrib -> publish_distrib ~dry_run ~yes pkg
    | `Alt kind -> publish_alt ~dry_run pkg kind
  in
  Pkg.publish_artefacts pkg >>= fun todo ->
  List.fold_left publish_artefact (Ok ()) todo >>= fun () -> Ok 0

let publish_cli () build_dir name pkg_names version tag keep_v opam delegate
    change_log distrib_uri distrib_file publish_msg dry_run publish_artefacts
    yes =
  publish ?build_dir ?opam ?delegate ?change_log ?distrib_uri ?distrib_file
    ?publish_msg ~name ~pkg_names ~version ~tag ~keep_v ~dry_run
    ~publish_artefacts ~yes ()
  |> Cli.handle_error

(* Command line interface *)

open Cmdliner

let delegate =
  let doc =
    "The delegate tool $(docv) to use. If absent, see dune-release-delegate(7) \
     for the lookup procedure."
  in
  let docv = "TOOL" in
  let to_cmd = function None -> None | Some s -> Some (Cmd.v s) in
  Term.(
    const to_cmd
    $ Arg.(value & opt (some string) None & info [ "delegate" ] ~doc ~docv))

let artefacts =
  let alt_prefix = "alt-" in
  let parser = function
    | "do" | "doc" -> `Ok `Doc
    | "di" | "dis" | "dist" | "distr" | "distri" | "distrib" -> `Ok `Distrib
    | s when String.is_prefix ~affix:alt_prefix s -> (
        match String.(with_range ~first:(length alt_prefix) s) with
        | "" -> `Error "`alt-' alternative artefact kind is missing"
        | kind -> `Ok (`Alt kind) )
    | s -> `Error (strf "`%s' unknown publication artefact" s)
  in
  let printer ppf = function
    | `Doc -> Fmt.string ppf "doc"
    | `Distrib -> Fmt.string ppf "distrib"
    | `Alt a -> Fmt.pf ppf "alt-%s" a
  in
  let artefact = (parser, printer) in
  let doc =
    strf
      "The artefact to publish. $(docv) must be either `doc` or `distrib`. If \
       absent, the set of default publication artefacts is determined by the \
       package description."
  in
  Arg.(value & pos_all artefact [] & info [] ~doc ~docv:"ARTEFACT")

let doc = "Publish package distribution archives and derived artefacts"

let sdocs = Manpage.s_common_options

let exits = Cli.exits

let envs =
  [
    Term.env_info "DUNE_RELEASE_DELEGATE"
      ~doc:"The package delegate to use, see dune-release-delegate(7).";
  ]

let man_xrefs = [ `Main; `Cmd "distrib" ]

let man =
  [
    `S Manpage.s_synopsis;
    `P "$(mname) $(tname) [$(i,OPTION)]... [$(i,ARTEFACT)]...";
    `S Manpage.s_description;
    `P
      "The $(tname) command publishes package distribution archives and other \
       artefacts.";
    `P
      "Artefact publication always relies on a distribution archive having \
       been generated before with dune-release-distrib(1).";
    `S "ARTEFACTS";
    `I ("$(b,distrib)", "Publishes a distribution archive on the WWW.");
    `I
      ( "$(b,doc)",
        "Publishes the documentation of a distribution archive on the WWW." );
    `I
      ( "$(b,alt)-$(i,KIND)",
        "Publishes the alternative artefact of kind $(i,KIND) of a \
         distribution archive. The semantics of alternative artefacts is left \
         to the delegate, it could be anything, an email, a pointless tweet, a \
         feed entry etc. See dune-release-delegate(7) for more details." );
  ]

let cmd =
  ( Term.(
      pure publish_cli $ Cli.setup $ Cli.build_dir $ Cli.dist_name
      $ Cli.pkg_names $ Cli.pkg_version $ Cli.dist_tag $ Cli.keep_v
      $ Cli.dist_opam $ delegate $ Cli.change_log $ Cli.dist_uri $ Cli.dist_file
      $ Cli.publish_msg $ Cli.dry_run $ artefacts $ Cli.yes),
    Term.info "publish" ~doc ~sdocs ~exits ~envs ~man ~man_xrefs )

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
