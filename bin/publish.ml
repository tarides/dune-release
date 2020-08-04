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
  App_log.status (fun l -> l "Publishing documentation");
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

let pp_field = Fmt.(styled `Bold string)

(* If `publish doc` is invoked explicitly from the CLI, we should fail if the
   documentation cannot be published. If it is not called explicitly, we can
   skip this step if the `doc` field of the opam file is not set, we do not
   generate nor publish the documentation, except when using a delegate. *)
let publish_doc ~specific ~dry_run ~yes pkg_names pkg =
  match Pkg.doc_uri pkg with
  | _ when specific -> publish_doc ~dry_run ~yes pkg_names pkg
  | Error _ | Ok "" -> (
      match Pkg.delegate pkg with
      | Ok (Some _) ->
          App_log.unhappy (fun l ->
              l Deprecate.Delegates.warning_usage
                Deprecate.Delegates.new_workflow);
          publish_doc ~dry_run ~yes pkg_names pkg
      | Error _ | Ok None ->
          Pkg.name pkg >>= fun name ->
          Pkg.opam pkg >>= fun opam ->
          App_log.status (fun l ->
              l
                "Skipping documentation publication for package %s: no %a \
                 field in %a"
                name pp_field "doc" Fpath.pp opam);
          Ok ())
  | Ok _ -> publish_doc ~dry_run ~yes pkg_names pkg

let publish_distrib ?token ?distrib_uri ~dry_run ~yes ~draft pkg =
  App_log.status (fun l -> l "Publishing distribution");
  Pkg.distrib_file ~dry_run pkg >>= fun archive ->
  Pkg.publish_msg pkg >>= fun msg ->
  Delegate.publish_distrib ?token ?distrib_uri ~dry_run ~yes pkg ~msg ~archive
    ~draft

let publish_alt ?distrib_uri ~dry_run pkg kind =
  App_log.status (fun l -> l "Publishing %s" kind);
  Pkg.distrib_file ~dry_run pkg >>= fun archive ->
  Pkg.publish_msg pkg >>= fun msg ->
  Delegate.publish_alt ?distrib_uri ~dry_run pkg ~kind ~msg ~archive

let publish ?build_dir ?opam ?delegate ?change_log ?distrib_uri ?distrib_file
    ?publish_msg ?token ~pkg_names ~version ~tag ~keep_v ~dry_run
    ~publish_artefacts ~yes ~draft () =
  let specific_doc =
    List.exists (function `Doc -> true | _ -> false) publish_artefacts
  in
  let publish_artefacts =
    match publish_artefacts with [] -> [ `Doc; `Distrib ] | v -> v
  in
  Config.keep_v keep_v >>= fun keep_v ->
  let pkg =
    Pkg.v ~dry_run ?version ?tag ~keep_v ?build_dir ?opam ?change_log
      ?distrib_file ?publish_msg ?delegate ()
  in
  let publish_artefact acc artefact =
    acc >>= fun () ->
    match artefact with
    | `Doc -> publish_doc ~specific:specific_doc ~dry_run ~yes pkg_names pkg
    | `Distrib -> publish_distrib ?token ?distrib_uri ~dry_run ~yes ~draft pkg
    | `Alt kind ->
        App_log.unhappy (fun l ->
            l Deprecate.Delegates.warning_usage_alt_artefacts
              Deprecate.Delegates.new_workflow);
        publish_alt ~dry_run pkg kind
  in
  List.fold_left publish_artefact (Ok ()) publish_artefacts >>= fun () -> Ok 0

let publish_cli () (`Build_dir build_dir) (`Package_names pkg_names)
    (`Package_version version) (`Dist_tag tag) (`Keep_v keep_v)
    (`Dist_opam opam) (`Delegate delegate) (`Change_log change_log)
    (`Dist_uri distrib_uri) (`Dist_file distrib_file) (`Publish_msg publish_msg)
    (`Dry_run dry_run) (`Publish_artefacts publish_artefacts) (`Yes yes)
    (`Token token) (`Draft draft) =
  publish ?build_dir ?opam ?delegate ?change_log ?distrib_uri ?distrib_file
    ?publish_msg ?token ~pkg_names ~version ~tag ~keep_v ~dry_run
    ~publish_artefacts ~yes ~draft ()
  |> Cli.handle_error

(* Command line interface *)

open Cmdliner

let delegate =
  let doc =
    "The delegate tool $(docv) to use. If absent, see dune-release-delegate(7) \
     for the lookup procedure. $(b,Warning:) " ^ Deprecate.Delegates.warning
  in
  let docv = "TOOL" in
  let to_cmd = function None -> None | Some s -> Some (Cmd.v s) in
  Cli.named
    (fun x -> `Delegate x)
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
        | kind ->
            App_log.unhappy (fun l ->
                l Deprecate.Delegates.warning_usage_alt_artefacts
                  Deprecate.Delegates.new_workflow);
            `Ok (`Alt kind))
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
  Cli.named
    (fun x -> `Publish_artefacts x)
    Arg.(value & pos_all artefact [] & info [] ~doc ~docv:"ARTEFACT")

let doc =
  "Publish package distribution archives and other artefacts. "
  ^ Deprecate.Delegates.artefacts_warning

let sdocs = Manpage.s_common_options

let exits = Cli.exits

let envs =
  [
    Term.env_info "DUNE_RELEASE_DELEGATE"
      ~doc:
        ("The package delegate to use, see dune-release-delegate(7). "
       ^ Deprecate.Delegates.env_var_warning);
  ]

let man_xrefs = [ `Main; `Cmd "distrib" ]

let man =
  [
    `S Manpage.s_synopsis;
    `P "$(mname) $(tname) [$(i,OPTION)]... [$(i,ARTEFACT)]...";
    `S Manpage.s_description;
    `P
      ("The $(tname) command publishes package distribution archives and other \
        artefacts. " ^ Deprecate.Delegates.artefacts_warning);
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
         feed entry etc. See dune-release-delegate(7) for more details. "
        ^ Deprecate.Delegates.artefacts_warning );
  ]

let cmd =
  ( Term.(
      pure publish_cli $ Cli.setup $ Cli.build_dir $ Cli.pkg_names
      $ Cli.pkg_version $ Cli.dist_tag $ Cli.keep_v $ Cli.dist_opam $ delegate
      $ Cli.change_log $ Cli.dist_uri $ Cli.dist_file $ Cli.publish_msg
      $ Cli.dry_run $ artefacts $ Cli.yes $ Cli.token $ Cli.draft),
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
