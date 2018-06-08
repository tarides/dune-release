(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup
open Dune_release

let gen_doc ~dry_run ~force dir pkg_name =
  let build_doc = Cmd.(v "jbuilder" % "build" % "-p" % pkg_name % "@doc") in
  let build_dir = Fpath.(dir / "_build" / "default" / "_doc") in
  let do_doc () = Sos.run ~dry_run ~force build_doc >>| fun () -> build_dir in
  R.join @@ Sos.with_dir ~dry_run dir do_doc ()

let publish_doc ~dry_run pkg =
  Pkg.distrib_file ~dry_run pkg
  >>= fun archive -> Pkg.publish_msg pkg
  >>= fun msg -> Archive.untbz ~dry_run ~clean:true archive
  >>= fun dir -> OS.Dir.exists dir
  >>= fun force -> Pkg.name pkg
  >>= fun name -> gen_doc ~dry_run ~force dir name
  >>= fun docdir -> Github.publish_doc ~dry_run pkg ~msg ~docdir

let publish_distrib ~token ~dry_run pkg =
  Pkg.distrib_file ~dry_run pkg
  >>= fun archive -> Pkg.publish_msg pkg
  >>= fun msg     -> Github.publish_distrib ~token ~dry_run pkg ~msg ~archive

let reset_terminal : (unit -> unit) option ref = ref None
let cleanup () = match !reset_terminal with None -> () | Some f -> f ()
let () = at_exit cleanup

let no_stdin_echo f =
  let open Unix in
  let attr = tcgetattr stdin in
  let reset () = tcsetattr stdin TCSAFLUSH attr in
  reset_terminal := Some reset;
  tcsetattr stdin TCSAFLUSH
    { attr with
      c_echo = false; c_echoe = false; c_echok = false; c_echonl = true; };
  let v = f () in
  reset ();
  reset_terminal := None;
  v

let get_token () =
  let rec aux () =
    match read_line () with
    | "" -> aux ()
    | s  -> s
    | exception End_of_file ->
        print_newline ();
        aux ()
    | exception (Sys.Break as e) ->
        print_newline ();
        raise e
  in
  no_stdin_echo aux

let token ~dry_run () =
  match OS.Env.var "HOME" with
  | None   -> R.error_msg "$HOME is undefined"
  | Some d ->
      let file = Fpath.(v d / "dune-release" / "config.yml") in
      OS.File.exists file >>= fun exists ->
      if exists then Ok file
      else if dry_run then Ok Fpath.(v "${token}")
      else (
        Fmt.pr
          "%a does not exist! To create a new token, visit \
           https://github.com/settings/tokens and click on \
           \"Generate New Token\". Pick a useful Token description \
           (for dune-release) and select only the 'public_repo' scope.\n\
           \n\
           token: %!" Fpath.pp file;
        let token = get_token () in
        OS.File.write ~mode:0o600 file token >>= fun () ->
        Ok file
      )

let publish ()
    build_dir keep_v name version opam change_log distrib_uri
    distrib_file publish_msg dry_run publish_artefacts
  =
  begin
    let publish_artefacts = match publish_artefacts with
    | [] -> None
    | v -> Some v
    in
    let pkg =
      Pkg.v ~dry_run ?name ?version ?build_dir ?opam ~drop_v:(not keep_v)
        ?change_log ?distrib_uri ?distrib_file ?publish_msg
        ?publish_artefacts ()
    in
    let publish_artefact acc artefact =
      acc >>= fun () -> match artefact with
      | `Doc     -> publish_doc ~dry_run pkg
      | `Distrib ->
          token ~dry_run () >>= fun token ->
          publish_distrib ~token ~dry_run pkg
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
  | `Doc -> Fmt.string ppf "doc"
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
        "Publishes the documentation of a distribution archive on the WWW."); ]

let cmd =
  Term.(pure publish $ Cli.setup $ Cli.build_dir $ Cli.keep_v $
        Cli.dist_name $ Cli.dist_version $ Cli.dist_opam $
        Cli.change_log $ Cli.dist_uri $ Cli.dist_file $
        Cli.publish_msg $ Cli.dry_run $ artefacts),
  Term.info "publish" ~doc ~sdocs ~exits ~man ~man_xrefs

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
