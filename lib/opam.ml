(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup

module D = struct
  let fetch_head = "${fetch_head}"
end

let os_tool_env name os =
  let pre = match os with `Build_os -> "BUILD_OS_" | `Host_os -> "HOST_OS_" in
  pre ^ String.Ascii.uppercase name

let os_bin_dir_env = function
  | `Build_os -> "BUILD_OS_BIN"
  | `Host_os -> "HOST_OS_XBIN"

let os_suff_env = function
  | `Build_os -> "BUILD_OS_SUFF"
  | `Host_os -> "HOST_OS_SUFF"

let ocamlfindable name =
  match name with
  | ( "ocamlc" | "ocamlcp" | "ocamlmktop" | "ocamlopt" | "ocamldoc" | "ocamldep"
    | "ocamlmklib" | "ocamlbrowser" ) as tool ->
      let toolchain = Cmd.empty in
      Some Cmd.(v "ocamlfind" %% toolchain % tool)
  | _ -> None

let tool name os =
  match OS.Env.var (os_tool_env name os) with
  | Some cmd -> Cmd.v cmd
  | None -> (
      match OS.Env.var (os_bin_dir_env os) with
      | Some path -> Cmd.v Fpath.(to_string @@ (v path / name))
      | None -> (
          match OS.Env.var (os_suff_env os) with
          | Some suff -> Cmd.v (name ^ suff)
          | None -> (
              match ocamlfindable name with
              | Some cmd -> cmd
              | None -> Cmd.v name)))

let cmd = Cmd.of_list @@ Cmd.to_list @@ tool "opam" `Host_os

(* Publish *)

let shortest x =
  List.hd (List.sort (fun x y -> compare (String.length x) (String.length y)) x)

let prepare_package ~dry_run ~version vcs name =
  OS.Dir.current () >>= fun cwd ->
  (* copy opam, descr and url files *)
  let dir = name ^ "." ^ version in
  let src = Fpath.(cwd / "_build" / dir) in
  let dst = Fpath.(v "packages" / name / dir) in
  let cp f =
    OS.File.exists Fpath.(src / f) >>= function
    | true ->
        Sos.cp ~dry_run ~rec_:false ~force:true
          ~src:Fpath.(src / f)
          ~dst:Fpath.(dst / f)
    | _ -> Ok ()
  in
  OS.Dir.exists src >>= fun exists ->
  (if exists then Ok ()
  else
    R.error_msgf
      "%a does not exist, did you run:\n  dune-release opam pkg -p %s\n"
      Fpath.pp src name)
  >>= fun () ->
  OS.Dir.create ~path:true dst >>= fun _ ->
  cp "opam" >>= fun () ->
  cp "url" >>= fun () ->
  cp "descr" >>= fun () ->
  (* git add *)
  Vcs.run_git_quiet vcs ~dry_run ~force:true Cmd.(v "add" % p dst)

let prepare ~dry_run ?msg ~local_repo ~remote_repo ~opam_repo ~version ~tag
    names =
  let msg =
    match msg with
    | None -> Ok Cmd.empty
    | Some msg ->
        OS.Dir.current () >>= fun cwd ->
        let file = Fpath.(cwd / "_build" / "submit-msg") in
        Sos.write_file ~dry_run ~force:true file msg >>| fun () ->
        Cmd.(v "--file" % p file)
  in
  msg >>= fun msg ->
  Sos.dir_exists ~dry_run Fpath.(local_repo / ".git") >>= fun exists ->
  (if exists then Ok ()
  else R.error_msgf "%a is not a valid Git repository." Fpath.pp local_repo)
  >>= fun () ->
  let git_for_repo r = Cmd.of_list (Cmd.to_list @@ Vcs.cmd r) in
  Vcs.get () >>= fun repo ->
  let git = git_for_repo repo in
  let upstream =
    let user, repo = opam_repo in
    Printf.sprintf "https://github.com/%s/%s.git" user repo
  in
  let remote_branch = "master" in
  let pkg = shortest names in
  let branch = Fmt.strf "release-%s-%s" pkg tag in
  let prepare_repo () =
    App_log.status (fun l ->
        l "Fetching %a" Text.Pp.url (upstream ^ "#" ^ remote_branch));
    Vcs.run_git_quiet repo ~dry_run ~force:true
      Cmd.(v "fetch" % upstream % remote_branch)
    >>= fun () ->
    Vcs.run_git_string repo ~dry_run ~force:true ~default:(Sos.out D.fetch_head)
      Cmd.(v "rev-parse" % "FETCH_HEAD")
    >>= fun id ->
    (* make a branch *)
    let delete_branch () =
      if not (Vcs.branch_exists ~dry_run:false repo branch) then Ok ()
      else
        match
          Vcs.run_git_quiet repo ~dry_run ~force:true
            Cmd.(v "checkout" % "master")
        with
        | Ok () ->
            Vcs.run_git_quiet repo ~dry_run ~force:true
              Cmd.(v "branch" % "-D" % branch)
        | Error _ ->
            let out = OS.Cmd.run_out Cmd.(git % "status") in
            OS.Cmd.out_lines out >>= fun (out, _) ->
            R.error_msgf "git checkout in %a failed:\n %s" Fpath.pp local_repo
              (String.concat ~sep:"\n" out)
    in
    delete_branch () >>= fun () ->
    App_log.status (fun l ->
        l "Checking out a local %a branch" Text.Pp.commit branch);
    Vcs.checkout repo ~dry_run:false ~branch ~commit_ish:id
  in
  let prepare_packages =
    Stdext.Result.List.iter ~f:(prepare_package ~dry_run ~version repo)
  in
  let commit_and_push () =
    Vcs.run_git_quiet repo ~dry_run Cmd.(v "commit" %% msg) >>= fun () ->
    App_log.status (fun l ->
        l "Pushing %a to %a" Text.Pp.commit branch Text.Pp.url remote_repo);
    Vcs.run_git_quiet repo ~dry_run
      Cmd.(v "push" % "--force" % remote_repo % branch)
  in
  Sos.with_dir ~dry_run local_repo
    (fun () ->
      prepare_repo () >>= fun () ->
      prepare_packages names >>= fun () ->
      commit_and_push () >>= fun () -> Ok branch)
    ()
  |> R.join

(* Files *)

module File = struct
  (* Try to compose with the OpamFile.OPAM API *)

  let id x = x

  let list f v = [ f v ]

  let field name field conv =
    (name, fun acc o -> String.Map.add name (conv (field o)) acc)

  let opt_field name field conv =
    ( name,
      fun acc o ->
        match field o with
        | None -> acc
        | Some v -> String.Map.add name (conv v) acc )

  let deps_conv d =
    let add_pkg acc (n, _) = OpamPackage.Name.to_string n :: acc in
    OpamFormula.fold_left add_pkg [] d

  let fields =
    [
      opt_field "name" OpamFile.OPAM.name_opt (list OpamPackage.Name.to_string);
      opt_field "version" OpamFile.OPAM.version_opt
        (list OpamPackage.Version.to_string);
      field "opam-version" OpamFile.OPAM.opam_version
        (list OpamVersion.to_string);
      field "available" OpamFile.OPAM.available (list OpamFilter.to_string);
      field "maintainer" OpamFile.OPAM.maintainer id;
      field "homepage" OpamFile.OPAM.homepage id;
      field "authors" OpamFile.OPAM.author id;
      field "license" OpamFile.OPAM.license id;
      field "doc" OpamFile.OPAM.doc id;
      field "tags" OpamFile.OPAM.tags id;
      field "bug-reports" OpamFile.OPAM.bug_reports id;
      opt_field "dev-repo" OpamFile.OPAM.dev_repo (list OpamUrl.to_string);
      field "depends" OpamFile.OPAM.depends deps_conv;
      field "depopts" OpamFile.OPAM.depopts deps_conv;
      opt_field "description" OpamFile.OPAM.descr_body (list id);
      opt_field "synopsis" OpamFile.OPAM.synopsis (list id);
    ]

  let fields ~dry_run file =
    if not (Sys.file_exists (Fpath.to_string file)) then
      R.error_msgf "Internal error: file %a not found" Fpath.pp file
    else
      let parse file =
        let file = OpamFilename.of_string (Fpath.to_string file) in
        let opam = OpamFile.OPAM.read (OpamFile.make file) in
        let known_fields =
          let add_field acc (_, field) = field acc opam in
          List.fold_left add_field String.Map.empty fields
        in
        (* FIXME add OpamFile.OPAM.extensions when supported *)
        known_fields
      in
      Logs.info (fun m -> m "Parsing opam file %a" Fpath.pp file);
      try Ok (parse file)
      with _ ->
        if dry_run then Ok String.Map.empty
        else
          (* Apparently in at least opam-lib 1.2.2, the error will be
             logged on stdout. *)
          R.error_msgf "%a: could not parse opam file" Fpath.pp file
end

module Descr = struct
  type t = string * string option

  let of_string s =
    match String.cuts ~sep:"\n" s with
    | [] -> assert false (* String.cuts never returns the empty list *)
    | [ synopsis ] | [ synopsis; "" ] -> Ok (synopsis, None)
    | synopsis :: descr -> Ok (synopsis, Some (String.concat ~sep:"\n" descr))

  let to_string = function
    | synopsis, None -> synopsis
    | synopsis, Some descr -> strf "%s\n%s" synopsis descr

  let of_readme ?flavour r =
    let parse_synopsis l =
      let error l = R.error_msgf "%S: can't extract opam synopsis" l in
      let ok s = Ok String.(Ascii.capitalize @@ String.Sub.to_string s) in
      let not_white c = not (Char.Ascii.is_white c) in
      let skip_non_white l = String.Sub.drop ~sat:not_white l in
      let skip_white l = String.Sub.drop ~sat:Char.Ascii.is_white l in
      let start = String.sub l |> skip_white |> skip_non_white |> skip_white in
      match String.Sub.head start with
      | None -> error l
      | Some c when Char.Ascii.is_letter c -> ok start
      | Some _ -> (
          (* Try to skip a separator. *)
          let start = start |> skip_non_white |> skip_white in
          match String.Sub.head start with
          | None -> error l
          | Some _ -> ok start)
    in
    let drop_line l =
      String.is_prefix ~affix:"Home page:" l
      || String.is_prefix ~affix:"Homepage:" l
      || String.is_prefix ~affix:"Contact:" l
      || String.is_prefix ~affix:"%%VERSION" l
    in
    let keep_line l = not (drop_line l) in
    match Text.head ?flavour r with
    | None -> R.error_msgf "Could not extract opam description."
    | Some (title, text) -> (
        let sep = "\n" in
        let title = Text.header_title ?flavour title in
        parse_synopsis title >>= fun synopsis ->
        Ok (String.cuts ~sep text) >>= fun text ->
        Ok (List.filter keep_line text) >>= function
        | [] | [ "" ] -> Ok (synopsis, None)
        | text -> Ok (synopsis, Some (String.concat ~sep text)))

  let of_readme_file file =
    let flavour = Text.flavour_of_fpath file in
    OS.File.read file
    >>= (fun text -> of_readme ?flavour text)
    |> R.reword_error_msg ~replace:true (fun m ->
           R.msgf "%a: %s" Fpath.pp file m)
end

module Url = struct
  let v ~uri ~file =
    let hash algo = OpamHash.compute ~kind:algo file in
    let checksum = List.map hash [ `SHA256; `SHA512 ] in
    let url = OpamUrl.parse uri in
    OpamFile.URL.create ~checksum url

  let with_distrib_file ~dry_run ~uri distrib_file =
    match OS.File.exists distrib_file with
    | Ok true ->
        let file = Fpath.to_string distrib_file in
        Ok (v ~uri ~file)
    | _ ->
        if dry_run then Ok OpamFile.URL.empty
        else OS.File.must_exist distrib_file >>= fun _ -> assert false
end

module Version = struct
  type t = V1_2_2 | V2

  let pp fs = function
    | V1_2_2 -> Format.fprintf fs "v1.2.2"
    | V2 -> Format.fprintf fs "v2"

  let equal v1 v2 =
    match (v1, v2) with V1_2_2, V1_2_2 | V2, V2 -> true | _ -> false

  let of_string v =
    if Bos_setup.String.is_prefix v ~affix:"1." then
      if String.equal v "1.2.2" then Ok V1_2_2
      else R.error_msgf "unsupported opam version: %S" v
    else
      match String.cut ~sep:"2." v with
      | Some ("", _) -> Ok V2
      | _ -> R.error_msgf "unsupported opam version: %S" v

  let cli () =
    match
      OS.Cmd.run_out Cmd.(cmd % "--version") |> OS.Cmd.out_string ~trim:true
    with
    | Ok (s, (_, `Exited 0)) ->
        of_string s >>= fun v ->
        if equal v V1_2_2 then
          Logs.warn (fun l ->
              l
                "opam %s is deprecated, and its support will be dropped in \
                 dune-release 2.0.0, please switch to opam 2.0"
                s);
        Ok v
    | Ok (_, (_, s)) -> R.error_msgf "opam: %a" OS.Cmd.pp_status s
    | Error (`Msg e) -> R.error_msgf "opam: %s" e

  let cli = lazy (cli ())
end

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
