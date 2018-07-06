(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup

let os_tool_env name os =
  let pre = match os with `Build_os -> "BUILD_OS_" | `Host_os -> "HOST_OS_" in
  pre ^ String.Ascii.uppercase name

let os_bin_dir_env = function
| `Build_os -> "BUILD_OS_BIN"
| `Host_os -> "HOST_OS_XBIN"

let os_suff_env = function
| `Build_os -> "BUILD_OS_SUFF"
| `Host_os -> "HOST_OS_SUFF"

let ocamlfindable name = match name with
| "ocamlc" | "ocamlcp" | "ocamlmktop" | "ocamlopt" | "ocamldoc" | "ocamldep"
| "ocamlmklib" | "ocamlbrowser" as tool ->
    let toolchain = Cmd.empty in
    Some Cmd.(v "ocamlfind" %% toolchain % tool)
| _ -> None

let tool name os = match OS.Env.var (os_tool_env name os) with
| Some cmd -> Cmd.v cmd
| None ->
    match OS.Env.var (os_bin_dir_env os) with
    | Some path -> Cmd.v Fpath.(to_string @@ v path / name)
    | None ->
        match OS.Env.var (os_suff_env os) with
        | Some suff -> Cmd.v (name ^ suff)
        | None ->
            match ocamlfindable name with
            | Some cmd -> cmd
            | None -> Cmd.v name

let cmd = Cmd.of_list @@ Cmd.to_list @@ tool "opam" `Host_os

(* Publish *)

let shortest x =
  List.hd (List.sort (fun x y -> compare (String.length x) (String.length y)) x)

let prepare ~dry_run ?msg ~local_repo ~remote_repo ~version names =
  let msg = match msg with
  | None -> Ok (Cmd.empty)
  | Some msg ->
      OS.Dir.current () >>= fun cwd ->
      let file = Fpath.(cwd / "_build" / "submit-msg") in
      Sos.write_file ~dry_run ~force:true file msg >>| fun () ->
      Cmd.(v "--file" % p file)
  in
  msg >>= fun msg ->
  Sos.dir_exists ~dry_run Fpath.(local_repo / ".git")
  >>= fun exists ->
  (if exists then Ok ()
   else R.error_msgf "%a is not a valid Git repository." Fpath.pp local_repo)
  >>= fun () ->
  let git_for_repo r = Cmd.of_list (Cmd.to_list @@ Vcs.cmd r) in
  Vcs.get () >>= fun repo ->
  let git = git_for_repo repo in
  let upstream = "https://github.com/ocaml/opam-repository.git" in
  let remote_branch = "master" in
  let pkg = shortest names in
  let branch = Fmt.strf "release-%s-%s" pkg version in
  let run = Sos.run ~sandbox:false ~dry_run ~force:true in
  let run_out = Sos.run_out ~sandbox:false ~dry_run ~force:true in
  let prepare_repo () =
    (* fetch from upstream *)
    let git_fetch = Cmd.(git % "fetch" % upstream % remote_branch) in
    run git_fetch >>= fun () ->
    run_out Cmd.(git % "rev-parse" % "FETCH_HEAD")
      ~default:"${fetch_head}" OS.Cmd.to_string
    >>= fun id ->
    (* make a branch *)
    let delete_branch () =
      if not (Vcs.branch_exists ~dry_run:false repo branch) then Ok ()
      else (
        run Cmd.(git % "checkout" % "master") >>= fun () ->
        run Cmd.(git % "branch" % "-D" % branch)
      )
    in
    delete_branch () >>= fun () ->
    Vcs.checkout repo ~dry_run:false ~branch ~commit_ish:id
  in
  OS.Dir.current () >>= fun cwd ->
  let prepare_package name =
    (* copy opam, descr and url files *)
    let dir = name ^ "." ^ version in
    let src = Fpath.(cwd / "_build" / dir) in
    let dst = Fpath.(v "packages" / name / dir) in
    let cp f =
      OS.File.exists Fpath.(src / f) >>= function
      | true -> run Cmd.(v "cp" % p Fpath.(src / f) % p Fpath.(dst / f))
      | _    -> Ok ()
    in
    OS.Dir.exists src >>= fun exists ->
    (if exists then Ok ()
     else
     R.error_msgf
       "%a does not exist, did you run:\n  dune-release opam pkg -n %s\n"
       Fpath.pp src name
    ) >>= fun () ->
    OS.Dir.create ~path:true dst >>= fun _ ->
    cp "opam"  >>= fun () ->
    cp "url"   >>= fun () ->
    cp "descr" >>= fun () ->
    (* git add *)
    run Cmd.(git % "add" % p dst)
  in
  let rec prepare_packages = function
  | []   -> Ok ()
  | h::t -> prepare_package h >>= fun () -> prepare_packages t
  in
  let commit_and_push () =
    run Cmd.(git % "commit" %% msg) >>= fun () ->
    Sos.run ~dry_run ~sandbox:false
      Cmd.(git % "push" % "--force" % remote_repo % branch)
  in
  Sos.with_dir ~dry_run local_repo (fun () ->
      prepare_repo () >>= fun () ->
      prepare_packages names >>= fun () ->
      commit_and_push () >>= fun () ->
      Ok branch
    ) () |> R.join

(* Packages *)

let ocaml_base_packages = String.Set.of_list
    [ "base-bigarray"; "base-bytes"; "base-threads"; "base-unix"; ]

(* Files *)

module File = struct

  (* Try to compose with the OpamFile.OPAM API *)

  let id x = x
  let list f = fun v -> [f v]
  let field name field conv =
    name, fun acc o -> String.Map.add name (conv (field o)) acc

  let opt_field name field conv =
    name, fun acc o -> match field o with
    | None -> acc
    | Some v -> String.Map.add name (conv v) acc

  let deps_conv d =
    let add_pkg acc (n, _) = OpamPackage.Name.to_string n :: acc in
    OpamFormula.fold_left add_pkg [] d

  let fields = [
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
  ]

  let field_names =
    let add acc (name, _) = String.Set.add name acc in
    List.fold_left add String.Set.empty fields

  let fields ~dry_run file =
    let parse file  =
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
    try Ok (parse file) with
    | _ ->
        if dry_run then Ok String.Map.empty else
        (* Apparently in at least opam-lib 1.2.2, the error will be
           logged on stdout. *)
        R.error_msgf "%a: could not parse opam file" Fpath.pp file

  let deps ?(opts = true) fields =
    let deps = match String.Map.find "depends" fields with
    | None -> [] | Some deps -> deps
    in
    let dep_opts =
      if not opts then [] else
      match String.Map.find "depopts" fields with
      | None -> []  | Some deps -> deps
    in
    String.Set.of_list (List.rev_append dep_opts deps)
end

module Descr = struct
  type t = string * string

  let of_string s = match String.cuts ~sep:"\n" s with
  | [] ->  R.error_msgf "Cannot extract opam descr."
  | synopsis :: descr -> Ok (synopsis, String.concat ~sep:"\n" descr)

  let to_string (synopsis, descr) = strf "%s\n%s" synopsis descr

  let of_readme ?flavour r =
    let parse_synopsis l =
      let error l = R.error_msgf "%S: can't extract opam synopsis" l in
      let ok s = Ok String.(Ascii.capitalize @@ String.Sub.to_string s) in
      let not_white c = not (Char.Ascii.is_white c) in
      let skip_non_white l = String.Sub.drop ~sat:not_white l in
      let skip_white l = String.Sub.drop ~sat:Char.Ascii.is_white l in
      let start =
        String.sub l |> skip_white |> skip_non_white |> skip_white
      in
      match String.Sub.head start with
      | None -> error l
      | Some c when Char.Ascii.is_letter c -> ok start
      | Some _ -> (* Try to skip a separator. *)
          let start = start |> skip_non_white |> skip_white in
          match String.Sub.head start with
          | None -> error l
          | Some _ -> ok start
    in
    let drop_line l =
      String.is_prefix ~affix:"Home page:" l ||
      String.is_prefix ~affix:"Homepage:" l ||
      String.is_prefix ~affix:"Contact:" l ||
      String.is_prefix ~affix:"%%VERSION" l
    in
    let keep_line l = not (drop_line l) in
    match Text.head ?flavour r with
    | None -> R.error_msgf "Could not extract opam description."
    | Some (title, text) ->
        let sep = "\n" in
        let title = Text.header_title ?flavour title in
        parse_synopsis title
        >>= fun synopsis -> Ok (String.cuts ~sep text)
        >>= fun text -> Ok (List.filter keep_line text)
        >>= fun text -> Ok (synopsis, String.concat ~sep text)

  let of_readme_file file =
    let flavour = Text.flavour_of_fpath file in
    (OS.File.read file
     >>= fun text -> of_readme ?flavour text)
    |> R.reword_error_msg ~replace:true
      (fun m -> R.msgf "%a: %s" Fpath.pp file m)
end

module Url = struct
  let v ~uri ~checksum = strf "archive: \"%s\"\nchecksum: \"%s\"" uri checksum
  let with_distrib_file ~dry_run ~uri distrib_file =
    match OS.File.exists distrib_file with
    | Ok true ->
        let checksum = Digest.(to_hex @@ file (Fpath.to_string distrib_file)) in
        Ok (v ~uri ~checksum)
    | _ ->
        if dry_run then Ok "<dry-run>"
        else (OS.File.must_exist distrib_file >>= fun _ -> assert false)
end

let opam_version () =
  let v =
    OS.Cmd.run_out Cmd.(cmd % "--version") |> OS.Cmd.out_string ~trim:true
  in
  let of_str = function
  | "1.2.2" -> `v1_2_2
  | s       ->
      match String.cut ~sep:"2." s with
      | Some ("", _) -> `v2
      | _ -> Fmt.failwith "opam: invalid version %s" s
  in
  match v with
  | Ok (v, (_, `Exited 0)) -> of_str v
  | Ok (_, (_, s)) -> Fmt.failwith "opam: %a" OS.Cmd.pp_status s
  | Error (`Msg e) -> Fmt.failwith "opam: %s" e

let version = lazy (opam_version ())

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
