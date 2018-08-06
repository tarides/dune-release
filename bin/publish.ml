(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup
open Dune_release

let gen_doc ~dry_run ~force dir pkg_name =
  let build_doc = Cmd.(v "jbuilder" % "build" % "-p" % pkg_name % "@doc") in
  let doc_dir = Fpath.(v "_build" / "default" / "_doc") in
  let html_dir = Fpath.(doc_dir / "_html") in
  let do_doc () =
    Sos.run ~dry_run ~force build_doc >>= fun () ->
    Sos.dir_exists ~dry_run html_dir >>| function
    | true  -> Fpath.(dir // html_dir)
    | false -> Fpath.(dir // doc_dir)
  in
  R.join @@ Sos.with_dir ~dry_run dir do_doc ()

let publish_doc ~dry_run pkg =
  Pkg.distrib_file ~dry_run pkg
  >>= fun archive -> Pkg.publish_msg pkg
  >>= fun msg -> Archive.untbz ~dry_run ~clean:true archive
  >>= fun dir -> OS.Dir.exists dir
  >>= fun force -> Pkg.name pkg
  >>= fun name -> gen_doc ~dry_run ~force dir name
  >>= fun docdir -> Delegate.publish_doc ~dry_run pkg ~msg ~docdir

let publish_distrib ~dry_run pkg =
  Pkg.distrib_file ~dry_run pkg
  >>= fun archive -> Pkg.publish_msg pkg
  >>= fun msg     -> Delegate.publish_distrib ~dry_run pkg ~msg ~archive

let publish_alt ~dry_run pkg kind =
  Pkg.distrib_file ~dry_run pkg
  >>= fun archive -> Pkg.publish_msg pkg
  >>= fun msg     -> Delegate.publish_alt ~dry_run pkg ~kind ~msg ~archive

let publish ()
    build_dir keep_v name opam delegate change_log distrib_uri
    distrib_file publish_msg dry_run publish_artefacts
  =
  begin
    let publish_artefacts = match publish_artefacts with
    | [] -> None
    | v -> Some v
    in
    let pkg =
      Pkg.v ~dry_run ?name ?build_dir ?opam ~drop_v:(not keep_v)
        ?change_log ?distrib_uri ?distrib_file ?publish_msg
        ?publish_artefacts ?delegate ()
    in
    let publish_artefact acc artefact =
      acc >>= fun () -> match artefact with
      | `Doc      -> publish_doc ~dry_run pkg
      | `Distrib  -> publish_distrib ~dry_run pkg
      | `Alt kind -> publish_alt ~dry_run pkg kind
    in
    Pkg.publish_artefacts pkg
    >>= fun todo -> List.fold_left publish_artefact (Ok ()) todo
    >>= fun () -> Ok 0
  end
  |> Cli.handle_error

(* Command line interface *)

open Cmdliner

let delegate =
  let doc =
    "The delegate tool $(docv) to use. If absent, see dune-release-delegate(7)
     for the lookup procedure."
  in
  let docv = "TOOL" in
  let to_cmd = function None -> None | Some s -> Some (Cmd.v s) in
  Term.(const to_cmd $
        Arg.(value & opt (some string) None & info ["delegate"] ~doc ~docv))

let artefacts =
  let alt_prefix = "alt-" in
  let parser = function
  | "do" | "doc" -> `Ok `Doc
  | "di" | "dis" | "dist" | "distr" | "distri" | "distrib" -> `Ok `Distrib
  | s when String.is_prefix ~affix:alt_prefix s ->
      begin match String.(with_range ~first:(length alt_prefix) s) with
      | "" -> `Error ("`alt-' alternative artefact kind is missing")
      | kind -> `Ok (`Alt kind)
      end

  | s -> `Error (strf "`%s' unknown publication artefact" s)
  in
  let printer ppf = function
  | `Doc     -> Fmt.string ppf "doc"
  | `Distrib -> Fmt.string ppf "distrib"
  | `Alt a   -> Fmt.pf ppf "alt-%s" a
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
let envs =
  [ Term.env_info "DUNE_RELEASE_DELEGATE" ~doc:"The package delegate to use, see
    dune-release-delegate(7)."; ]

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
    `I ("$(b,alt)-$(i,KIND)",
        "Publishes the alternative artefact of kind $(i,KIND) of
         a distribution archive. The semantics of alternative artefacts
         is left to the delegate, it could be anything, an email,
         a pointless tweet, a feed entry etc. See dune-release-delegate(7) for
         more details.");
  ]

let cmd =
  Term.(pure publish $ Cli.setup $ Cli.build_dir $ Cli.keep_v $
        Cli.pkg_name $ Cli.dist_opam $
        delegate $ Cli.change_log $ Cli.dist_uri $ Cli.dist_file $
        Cli.publish_msg $ Cli.dry_run $ artefacts),
  Term.info "publish" ~doc ~sdocs ~exits ~envs ~man ~man_xrefs

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
