(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup
open Dune_release

let get_pkg_dir pkgs opam_pkg_dir = match pkgs, opam_pkg_dir with
| _   , Some d -> Ok d
| []  , _      -> assert false
| p::_, None   ->
    Pkg.build_dir p
    >>= fun bdir -> Pkg.distrib_filename ~opam:true p
    >>= fun fname -> Ok Fpath.(bdir // fname)

let rec descr = function
| []   -> Ok 0
| h::t ->
    Pkg.opam_descr h >>= fun d ->
    Logs.app (fun m -> m "%s" (Opam.Descr.to_string d));
    if t <> [] then Logs.app (fun m -> m "---\n");
    descr t

module D = struct
  let distrib_uri = "${distrib_uri}"
end

let pkg ~dry_run pkgs dist_pkg opam_pkg_dir =
  let log_pkg dir =
    Logs.app (fun m -> m "Wrote opam package %a" Text.Pp.path dir)
  in
  let warn_if_vcs_dirty () =
    Cli.warn_if_vcs_dirty "The opam package may be inconsistent with the \
                           distribution."
  in
  get_pkg_dir pkgs opam_pkg_dir >>= fun dir ->
  let one pkg =
    Pkg.opam pkg
    >>= fun opam_f -> OS.File.read opam_f
    >>= fun opam -> Pkg.opam_descr pkg
    >>= fun descr -> Ok (Opam.Descr.to_string descr)
    >>= fun descr -> OS.Path.exists opam_f
    >>= fun exists -> Pkg.distrib_file ~dry_run dist_pkg
    >>= fun distrib_file ->
    (if dry_run && not exists then Ok D.distrib_uri else Pkg.distrib_uri dist_pkg)
    >>= fun uri -> Opam.Url.with_distrib_file ~dry_run ~uri distrib_file
    >>= fun url -> OS.Dir.exists dir
    >>= fun exists -> (if exists then Sos.delete_dir ~dry_run dir else Ok ())
    >>= fun () -> OS.Dir.create dir
    >>= fun _ -> Sos.write_file ~dry_run Fpath.(dir / "descr") descr
    >>= fun () -> Sos.write_file ~dry_run Fpath.(dir / "opam") opam
    >>= fun () -> Sos.write_file ~dry_run Fpath.(dir / "url") url
    >>= fun () -> log_pkg dir; (if not dry_run then warn_if_vcs_dirty () else Ok ())
  in
  let rec loop = function
  | []   -> Ok 0
  | h::t -> one h >>= fun () -> loop t
  in
  loop pkgs

let github_issue = Re.(compile @@ seq [
    group (compl [alpha]);
    group (seq [char '#'; rep1 digit]);
  ])

let rewrite_github_refs user repo msg =
  Re.replace github_issue msg
    ~f:(fun s ->
        let x = Re.Group.get s 1 in
        let y = Re.Group.get s 2 in
        Fmt.strf "%s%s/%s%s" x user repo y)

let rec pp_list pp ppf = function
  | []    -> ()
  | [x]   -> pp ppf x
  | [x;y] -> Fmt.pf ppf "%a and %a" pp x pp y
  | h::t  -> Fmt.pf ppf "%a, %a" pp h (pp_list pp) t

let rec list_map f = function
| []   -> Ok []
| h::t -> f h >>= fun h -> list_map f t >>= fun t -> Ok (h :: t)

let submit ~dry_run opam_pkg_dir local_repo remote_repo pkgs =
  Config.token ~dry_run () >>= fun token ->
  get_pkg_dir pkgs opam_pkg_dir
  >>= fun pkg_dir -> Sos.dir_exists ~dry_run pkg_dir
  >>= function
  | false ->
      Logs.err (fun m -> m "Package@ %a@ does@ not@ exist. Did@ you@ forget@ \
                            to@ invoke 'dune-release opam pkg' ?" Fpath.pp pkg_dir);
      Ok 1
  | true ->
      Logs.app (fun m -> m "Submitting %a" Text.Pp.path pkg_dir);
      let pkg = List.hd pkgs in
      Pkg.version pkg >>= fun version ->
      list_map Pkg.name pkgs >>= fun names ->
      let title =
        strf "[new release] %a (%s)" (pp_list Fmt.string) names version
      in
      Pkg.publish_msg pkg >>= fun changes ->
      Pkg.distrib_user_and_repo pkg >>= fun (user, repo) ->
      let changes = rewrite_github_refs user repo changes in
      let msg = strf "%s\n\n%s\n" title changes in
      Opam.prepare ~dry_run ~msg ~local_repo ~remote_repo ~version names
      >>= fun branch ->
      (* open a new PR *)
      Pkg.opam_descr pkg >>= fun (syn, _) ->
      Pkg.opam_homepage pkg >>= fun homepage ->
      Pkg.opam_doc pkg >>= fun doc ->
      let pp_link name ppf = function
      | None -> () | Some h -> Fmt.pf ppf "- %s: <a href=%S>%s</a>\n" name h h
      in
      let pp_space ppf () =
        if homepage <> None || doc <> None then Fmt.string ppf "\n"
      in
      let msg =
        strf "%s\n\n%a%a%a##### %s"
          syn
          (pp_link "Project page") homepage
          (pp_link "Documentation") doc
          pp_space ()
          changes
      in
      Github.open_pr ~token ~dry_run ~title ~user ~branch msg >>= function
      | `Already_exists -> Logs.app (fun m ->
          m "\nThe existing pull request for %a has been automatically updated."
            Fmt.(styled `Bold string) (user ^ ":" ^ branch));
          Ok 0
      | `Url url ->
          let auto_open =
            if OpamStd.Sys.(os () = Darwin) then "open" else "xdg-open"
          in
          match Sos.run ~dry_run Cmd.(v auto_open % url) with
          | Ok ()   -> Ok 0
          | Error _ ->
              Logs.app (fun m ->
                  m "A new pull-request has been created at %s\n" url
                );
              Ok 0

let field pkgs field = match field with
| None -> Logs.err (fun m -> m "Missing FIELD positional argument"); Ok 1
| Some field ->
    let rec loop = function
    | []   -> Ok 0
    | h::t ->
        Pkg.opam_field h field >>= function
        | Some v -> Logs.app (fun m -> m "%s" (String.concat ~sep:" " v)); loop t
        | None ->
            Pkg.opam h >>= fun opam ->
            Logs.err (fun m -> m "%a: field %s is undefined" Fpath.pp opam field);
            Ok 1
    in
    loop pkgs

(* Command *)

let opam () dry_run build_dir local_repo remote_repo user keep_v
    name dist_opam dist_uri dist_file
    pkg_opam_dir pkg_names pkg_version pkg_opam pkg_descr
    readme change_log publish_msg action field_name
  =
  let pkg_names = match pkg_names with
  | [] -> [None]
  | l  -> List.map (fun n -> Some n) l
  in
  let pkgs = List.map (fun name ->
      Pkg.v ~dry_run ~drop_v:(not keep_v)
        ?build_dir ?name ?version:pkg_version ?opam:pkg_opam
        ?opam_descr:pkg_descr ?readme ?change_log ?publish_msg ()
    ) pkg_names
  in
  begin match action with
  | `Descr -> descr pkgs
  | `Pkg ->
      let dist_p =
        Pkg.v ~dry_run ~drop_v:(not keep_v)
          ?build_dir ?name ?opam:dist_opam
          ?distrib_uri:dist_uri ?distrib_file:dist_file ?readme ?change_log
          ?publish_msg ()
      in
      pkg ~dry_run pkgs dist_p pkg_opam_dir
  | `Submit ->
      Config.v ~user ~local_repo ~remote_repo pkgs >>= fun config ->
      (match local_repo with
      | Some r -> Ok Fpath.(v r)
      | None   ->
          match config.local with
          | Some r -> Ok r
          | None   -> R.error_msg "Unknown local repository.")
      >>= fun local_repo ->
      (match remote_repo with
      | Some r -> Ok r
      | None ->
          match config.remote with
          | Some r -> Ok r
          | None   -> R.error_msg "Unknown remote repository.")
      >>= fun remote_repo ->
      submit ~dry_run pkg_opam_dir local_repo remote_repo pkgs
  | `Field -> field pkgs field_name
  end
  |> Cli.handle_error

(* Command line interface *)

open Cmdliner

let action =
  let action = [ "descr", `Descr; "pkg", `Pkg; "submit", `Submit;
                 "field", `Field ]
  in
  let doc = strf "The action to perform. $(docv) must be one of %s."
      (Arg.doc_alts_enum action)
  in
  let action = Arg.enum action in
  Arg.(required & pos 0 (some action) None & info [] ~doc ~docv:"ACTION")

let field =
  let doc = "the field to output ($(b,field) action)" in
  Arg.(value & pos 1 (some string) None & info [] ~doc ~docv:"FIELD")

let user =
  let doc =
    "the name of the GitHub account where to push new opam-repository branches."
  in
  Arg.(value & opt (some string) None & info ["u"; "user"] ~doc ~docv:"USER")

let local_repo =
  let doc = "Location of the local fork of opam-repository" in
  let env = Arg.env_var "DUNE_RELEASE_LOCAL_REPO" in
  Arg.(value & opt (some string) None
       & info ~env ["l"; "--local-repo"] ~doc ~docv:"PATH")

let remote_repo =
  let doc = "Location of the remote fork of opam-repository" in
  let env = Arg.env_var "DUNE_RELEASE_REMOTE_REPO" in
  Arg.(value & opt (some string) None
       & info ~env ["r"; "--remote-repo"] ~doc ~docv:"URI")

let pkg_opam_dir =
  let doc = "Directory to use to write the opam package. If absent the
             directory $(i,BUILD_DIR)/$(i,PKG_NAME).$(i,PKG_VERSION) of the
             build directory is used (see options $(b,--build-dir),
             $(b,--pkg-name) and $(b,--pkg-version))"
  in
  let docv = "DIR" in
  Arg.(value & opt (some Cli.path_arg) None & info ["pkg-opam-dir"] ~doc ~docv)

let pkg_version =
  let doc = "The version string $(docv) of the opam package. If absent provided
             provided by the VCS tag description of the HEAD commit."
  in
  let docv = "PKG_NAME" in
  Arg.(value & opt (some string) None & info ["pkg-version"] ~doc ~docv)

let pkg_opam =
  let doc = "The opam file to use for the opam package. If absent uses the
             opam file mentioned in the package description that corresponds
             to the opam package name $(i,PKG_NAME) (see option
             $(b,--pkg-name))"
  in
  let docv = "FILE" in
  Arg.(value & opt (some Cli.path_arg) None & info ["pkg-opam"] ~doc ~docv)

let pkg_descr =
  let doc = "The opam descr file to use for the opam package. If absent and
             the opam file name (see $(b,--pkg-opam)) has a `.opam`
             extension, uses an existing file with the same path but a `.descr`
             extension. If the opam file name is `opam` uses a `descr`
             file in the same directory. If these files are not found
             a description is extracted from the the readme (see
             option $(b,--readme)) as follow: the first marked up
             section of the readme is extracted, its title is parsed
             according to the pattern '\\$(NAME) \\$(SEP) \\$(SYNOPSIS)',
             the body of the section is the long description. A few
             lines are filtered out: lines that start with either
             'Home page:', 'Contact:' or '%%VERSION'."
  in
  let docv = "FILE" in
  Arg.(value & opt (some Cli.path_arg) None & info ["pkg-descr"] ~doc ~docv)

let doc = "Interaction with opam and the OCaml opam repository"
let sdocs = Manpage.s_common_options
let envs = [  ]

let pkg_names =
  let doc = "The names $(docv) of the opam package to release. If absent provided
             by the package description."
  in
  let docv = "PKG_NAME" in
  Arg.(value & opt (list string) [] & info ["p"; "pkg-names"] ~doc ~docv)

let man_xrefs = [`Main; `Cmd "distrib" ]
let man =
  [ `S Manpage.s_synopsis;
    `P "$(mname) $(tname) [$(i,OPTION)]... $(i,ACTION)";
    `S Manpage.s_description;
    `P "The $(tname) command provides a few actions to interact with
        opam and the OCaml opam repository.";
    `S "ACTIONS";
    `I ("$(b,descr)",
        "extract and print an opam descr file. This is used by the
         $(b,pkg) action. See the $(b,--pkg-descr) option for details.");
    `I ("$(b,pkg)",
        "create an opam package description for a distribution.
         The action needs a distribution archive to operate, see
         dune-release-distrib(1) or the $(b,--dist-file) option.");
    `I ("$(b,submit)",
        "submits a package created with the action $(b,pkg) the OCaml
         opam repository. This requires configuration to be created
         manually first, see $(i, dune-release help files) for more
         details.");
    `I ("$(b,field) $(i,FIELD)",
        "outputs the field $(i,FIELD) of the package's opam file."); ]

let cmd =
  let info = Term.info "opam" ~doc ~sdocs ~envs ~man ~man_xrefs in
  let t = Term.(pure opam $ Cli.setup $ Cli.dry_run $ Cli.build_dir $
                local_repo $ remote_repo $
                user $ Cli.keep_v $
                Cli.pkg_name $ Cli.dist_opam $
                Cli.dist_uri $ Cli.dist_file $
                pkg_opam_dir $ pkg_names $ pkg_version $ pkg_opam $
                pkg_descr $ Cli.readme $ Cli.change_log $ Cli.publish_msg $
                action $ field)
  in
  (t, info)

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
