(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup

(* Package *)

type t = {
  name : string;
  tag : Vcs.Tag.t option;
  version : Version.t option;
  keep_v : bool;
  build_dir : Fpath.t option;
  opam : Fpath.t option;
  opam_descr : Fpath.t option;
  opam_fields : (string list String.map, R.msg) result Lazy.t;
  readmes : Fpath.t list option;
  change_logs : Fpath.t list option;
  licenses : Fpath.t list option;
  distrib_file : Fpath.t option;
  publish_msg : string option;
  project_name : string option;
}

let opam_fields p = Lazy.force p.opam_fields
let opam_field p f = opam_fields p >>| fun fields -> String.Map.find f fields

let opam_field_hd p f =
  opam_field p f >>| function None | Some [] -> None | Some (v :: _) -> Some v

let opam_homepage p = opam_field_hd p "homepage"
let opam_doc p = opam_field_hd p "doc"

let opam_homepage_sld p =
  opam_homepage p >>| Stdext.Option.bind ~f:Uri_helpers.get_sld

let name p = Ok p.name
let with_name p name = { p with name }
let project_name p = p.project_name

let extract_version change_log =
  Text.change_log_file_last_entry change_log >>= fun (version, _) -> Ok version

let find_files path ~names_wo_ext =
  OS.Dir.contents path >>| fun files ->
  Stdext.Path.find_files files ~names_wo_ext

let change_logs p =
  match p.change_logs with
  | Some f -> Ok f
  | None -> find_files (Fpath.v ".") ~names_wo_ext:[ "changes"; "changelog" ]

let change_log p =
  change_logs p >>= function
  | [] -> R.error_msgf "No change log specified in the package description."
  | l :: _ -> Ok l

let tag p =
  match p.tag with Some tag -> Ok tag | None -> Vcs.get () >>= Vcs.get_tag

let version_from_tag pkg =
  tag pkg >>= fun tag ->
  Vcs.get () >>= fun vcs -> Ok (Version.from_tag ~keep_v:pkg.keep_v vcs tag)

let extract_version pkg = change_log pkg >>= fun cl -> extract_version cl

let version p =
  match p.version with Some v -> Ok v | None -> version_from_tag p

let release_identifier pkg =
  match pkg.tag with
  | Some t -> Ok (strf "%a" Vcs.Tag.pp t)
  | None -> version pkg >>= fun version -> Ok (strf "%a" Version.pp version)

let build_dir p =
  match p.build_dir with Some b -> Ok b | None -> Ok (Fpath.v "_build")

let readmes p =
  match p.readmes with
  | Some f -> Ok f
  | None -> find_files (Fpath.v ".") ~names_wo_ext:[ "readme" ]

let readme p =
  readmes p >>= function
  | [] -> R.error_msgf "No readme file specified in the package description"
  | r :: _ -> Ok r

let opam p =
  match p.opam with
  | Some f -> Ok f
  | None ->
      name p >>= fun name ->
      let filename = name |> Fpath.v |> Fpath.add_ext ".opam" in
      let opam_subdir = Fpath.v "opam" in
      let in_opam_subdir = Fpath.append opam_subdir filename in
      OS.File.exists in_opam_subdir
      |> Result.map (function true -> in_opam_subdir | false -> filename)

let opam_descr p =
  let descr_file_for_opam opam =
    if Fpath.has_ext ".opam" opam then Fpath.(rem_ext opam + ".descr")
    else Fpath.(parent opam / "descr")
  in
  let read f = OS.File.read f >>= fun c -> Opam.Descr.of_string c in
  match p.opam_descr with
  | Some f -> read f
  | None -> (
      opam p >>= fun opam ->
      opam_field_hd p "opam-version" >>= function
      | Some "2.0" -> (
          opam_field_hd p "synopsis" >>= fun s ->
          opam_field_hd p "description" >>= fun d ->
          match s with
          | Some s -> Ok (s, d)
          | None -> R.error_msgf "missing synopsis")
      | Some ("1.2" | "1.0") -> (
          let descr_file = descr_file_for_opam opam in
          OS.File.exists descr_file >>= function
          | true ->
              Logs.info (fun m ->
                  m "Found opam descr file %a" Fpath.pp descr_file);
              read descr_file
          | false ->
              readme p >>= fun readme ->
              Logs.info (fun m ->
                  m "Extracting opam descr from %a" Fpath.pp readme);
              Opam.Descr.of_readme_file readme)
      | Some v -> R.error_msgf "unsupported opam version: %s" v
      | None -> R.error_msgf "missing opam-version field")

let licenses p =
  match p.licenses with
  | Some f -> Ok f
  | None -> find_files (Fpath.v ".") ~names_wo_ext:[ "license"; "copying" ]

let dev_repo p =
  opam_field_hd p "dev-repo" >>= function
  | None -> Ok None
  | Some r -> Ok (Some (Uri_helpers.chop_git_prefix r))

let dev_repo_is_on_github p =
  opam_field_hd p "dev-repo" >>| function
  | None -> false
  | Some r -> (
      match String.cut ~sep:"git@github.com:" r with
      | Some ("", _) -> true
      | _ -> (
          match String.cut ~sep:"git+ssh://git@github.com/" r with
          | Some ("", _) -> true
          | _ -> false))

let homepage_is_on_github p =
  opam_homepage_sld p >>| function None -> false | Some sld -> sld = "github"

let path_of_distrib p =
  dev_repo_is_on_github p >>= fun repo_on_gh ->
  homepage_is_on_github p >>= fun hp_on_gh ->
  name p >>= fun name ->
  release_identifier p >>= fun identifier ->
  let basename =
    match p.distrib_file with
    | Some f -> Fpath.basename f
    | None -> strf "%s-%s.tbz" name identifier
  in
  let filename =
    if repo_on_gh || hp_on_gh then
      strf "releases/download/%s/%s" identifier basename
    else "releases/" ^ basename
  in
  Ok filename

let infer_github_repo pkg =
  opam_homepage pkg >>= fun homepage ->
  match Stdext.Option.O.(homepage >>= Github_repo.from_uri) with
  | Some gh_repo -> Ok gh_repo
  | None -> (
      opam_field_hd pkg "dev-repo" >>= fun dev_repo ->
      match Stdext.Option.O.(dev_repo >>= Github_repo.from_uri) with
      | Some gh_repo -> Ok gh_repo
      | None ->
          R.error_msg
            "Github development repository URL could not be inferred from opam \
             files.")

let infer_github_distrib_uri pkg =
  infer_github_repo pkg >>= fun gh_repo ->
  let base_uri = Github_repo.https_uri gh_repo in
  path_of_distrib pkg >>= fun rel_path ->
  Ok (Uri_helpers.append_to_base ~rel_path base_uri)

let distrib_opam_path p =
  name p >>= fun name ->
  version p >>= fun version ->
  Fpath.of_string (strf "%s.%a" name Version.pp version)

let distrib_archive_filename_prefix pkg =
  name pkg >>= fun name ->
  release_identifier pkg >>= fun identifier ->
  Fpath.of_string (strf "%s-%s" name identifier)

let distrib_archive_path p =
  build_dir p >>= fun build_dir ->
  distrib_archive_filename_prefix p >>| fun b ->
  Fpath.((build_dir // b) + ".tbz")

let archive_url_path p =
  build_dir p >>= fun build_dir ->
  release_identifier p >>= fun identifier ->
  Fpath.of_string (strf "asset-%s" identifier) >>| fun b ->
  Fpath.((build_dir // b) + "url")

let distrib_file ~dry_run p =
  match p.distrib_file with
  | Some f -> Ok f
  | None ->
      distrib_archive_path p
      >>= (fun f -> Sos.file_must_exist ~dry_run f)
      |> R.reword_error_msg (fun _ ->
             R.msgf "Did you forget to call 'dune-release distrib' ?")

let doc_dir = Fpath.(v "_build" / "default" / "_doc" / "_html")

let publish_msg p =
  match p.publish_msg with
  | Some msg -> Ok msg
  | None ->
      change_log p >>= Text.change_log_file_last_entry >>| fun (_, (_, txt)) ->
      strf "CHANGES:\n\n%s\n" txt

let dune_project_name_string contents =
  let opam_pkg_name_char = Re.(alt [ wordc; char '-' ]) in
  let re =
    Re.(
      compile
        (seq
           [
             str "(";
             rep space;
             str "name";
             rep space;
             group (rep opam_pkg_name_char);
             rep space;
             str ")";
           ]))
  in
  Option.map (fun group -> Re.Group.get group 1) (Re.exec_opt re contents)

let dune_project_name dir =
  let file = Fpath.(dir / "dune-project") in
  Bos.OS.File.exists file >>= function
  | false -> Ok None
  | true -> Bos.OS.File.read file >>| dune_project_name_string

let infer_pkg_names dir = function
  | [] ->
      let remove_extension =
        List.map (fun p -> Fpath.(basename @@ rem_ext p))
      in
      let collect dir =
        Bos.OS.Dir.contents ~dotfiles:false ~rel:false dir >>= fun files ->
        let files = List.fast_sort Fpath.compare files |> List.rev in
        let opam_files =
          List.filter
            (fun p -> String.is_suffix ~affix:".opam" Fpath.(to_string p))
            files
        in
        Ok (remove_extension opam_files)
      in
      Result.bind (collect dir) (function
        | [] ->
            let opam_subdir = Fpath.(dir / "opam") in
            Result.bind (collect opam_subdir) (function
              | [] -> Rresult.R.error_msg "no <package>.opam files found."
              | opam_files -> Ok opam_files)
        | opam_files -> Ok opam_files)
  | x -> Ok x

let infer_from_opam_files dir =
  infer_pkg_names dir [] >>= fun package_names ->
  let shortest =
    match package_names with
    | [] -> assert false
    | first :: rest ->
        List.fold_left
          (fun acc s -> if String.length s < String.length acc then s else acc)
          first rest
  in
  if List.for_all (String.is_prefix ~affix:shortest) package_names then
    Ok (Some shortest)
  else Ok None

let infer_from_readme dir =
  let file = Fpath.(dir / "README.md") in
  Bos.OS.File.exists file >>= function
  | false -> Ok None
  | true -> (
      Bos.OS.File.read_lines file >>= function
      | [] -> Ok None
      | h :: _ -> (
          let name =
            String.trim ~drop:(function '#' | ' ' -> true | _ -> false) h
          in
          Bos.OS.File.exists (Fpath.v (name ^ ".opam")) >>| function
          | false -> None
          | true -> Some name))

let try_infer_name dir =
  dune_project_name dir >>= function
  | Some n -> Ok (Some n)
  | None -> (
      infer_from_opam_files dir >>= function
      | Some n -> Ok (Some n)
      | None -> (
          infer_from_readme dir >>= function
          | Some n -> Ok (Some n)
          | None -> Ok None))

let infer_name_err : ('a, Format.formatter, unit, unit, unit, 'a) format6 =
  "cannot determine distribution name automatically: add (name <name>) to \
   dune-project"

let infer_name dir =
  try_infer_name dir >>| function
  | Some name -> name
  | None ->
      Logs.err (fun m -> m infer_name_err);
      exit 1

let main pkgs =
  let pkg_opt =
    List.find_opt
      (fun pkg ->
        match (project_name pkg, name pkg) with
        | Some project_name, Ok name -> String.equal project_name name
        | _ -> false)
      pkgs
  in
  match pkg_opt with Some p -> p | None -> List.hd pkgs

let version_of_changelog pkg = Version.Changelog.to_version ~keep_v:pkg.keep_v

let v ~dry_run ?name ?version ?tag ?(keep_v = false) ?build_dir ?opam:opam_file
    ?opam_descr ?readme ?change_log ?license ?distrib_file ?publish_msg
    ?project_name () =
  let project_name_result = lazy (infer_name Fpath.(v ".")) in
  let project_name =
    match project_name with
    | Some r -> r
    | None -> (
        match Lazy.force project_name_result with
        | Ok s -> Some s
        | Error _ -> None)
  in
  let name =
    match name with None -> Lazy.force project_name_result | Some v -> Ok v
  in
  let readmes = match readme with Some r -> Some [ r ] | None -> None in
  let change_logs =
    match change_log with Some c -> Some [ c ] | None -> None
  in
  let licenses = match license with Some l -> Some [ l ] | None -> None in
  let name = Rresult.R.error_msg_to_invalid_arg name in
  let rec opam_fields = lazy (opam p >>= fun o -> Opam.File.fields ~dry_run o)
  and p =
    {
      name;
      version;
      tag;
      keep_v;
      build_dir;
      opam = opam_file;
      opam_descr;
      opam_fields;
      readmes;
      change_logs;
      licenses;
      distrib_file;
      publish_msg;
      project_name;
    }
  in
  p

(* Distrib *)

let version_line_re =
  let open Re in
  seq
    [
      bos;
      str "version:";
      rep space;
      char '"';
      rep1 any;
      char '"';
      rep space;
      eos;
    ]

let prepare_opam_for_distrib ~version ~content =
  let re = Re.compile version_line_re in
  let is_not_version_field line = not (Re.execp re line) in
  let without_version = List.filter is_not_version_field content in
  Fmt.str "version: \"%a\"" Version.pp version :: without_version

let opam_file_contents name =
  let filename = name |> Fpath.v |> Fpath.add_ext ".opam" in
  let location =
    OS.File.exists filename >>= function
    | true -> Ok filename
    | false -> (
        let filename = Fpath.append (Fpath.v "opam") filename in
        OS.File.exists filename >>= function
        | true -> Ok filename
        | false -> Rresult.R.error_msgf "Can't open %a" Fpath.pp filename)
  in
  location >>= fun filename ->
  OS.File.read_lines filename >>| fun content -> (filename, content)

let distrib_version_opam_files ~dry_run ~version =
  infer_pkg_names Fpath.(v ".") [] >>= fun names ->
  Stdext.Result.List.iter names ~f:(fun name ->
      opam_file_contents name >>= fun (file, content) ->
      let content = prepare_opam_for_distrib ~version ~content in
      Sos.write_file ~dry_run file (String.concat ~sep:"\n" content))

let distrib_prepare ~dry_run ~dist_build_dir ~version =
  Sos.with_dir ~dry_run dist_build_dir
    (fun () ->
      Sos.run ~dry_run Cmd.(v "dune" % "subst") >>= fun () ->
      distrib_version_opam_files ~dry_run ~version)
    ()
  |> R.join

let assert_tag_exists ~dry_run repo tag =
  if Vcs.tag_exists ~dry_run repo tag then Ok ()
  else R.error_msgf "%a is not a valid tag" Vcs.Tag.pp tag

let pull_submodules ~dry_run ~dist_build_dir =
  Sos.with_dir ~dry_run dist_build_dir
    (fun () -> Vcs.get () >>= Vcs.submodule_update ~dry_run)
    ()
  |> R.join

let distrib_archive ~dry_run ~keep_dir ~include_submodules p =
  Archive.ensure_bzip2 () >>= fun () ->
  build_dir p >>= fun build_dir ->
  tag p >>= fun tag ->
  version p >>= fun version ->
  distrib_archive_filename_prefix p >>= fun root ->
  Ok Fpath.((build_dir // root) + ".build") >>= fun dist_build_dir ->
  Sos.delete_dir ~dry_run ~force:true dist_build_dir >>= fun () ->
  Vcs.get () >>= fun repo_vcs ->
  assert_tag_exists ~dry_run repo_vcs tag >>= fun () ->
  Vcs.commit_ptime_s repo_vcs ~dry_run ~commit_ish:(Tag tag) >>= fun mtime ->
  Vcs.clone ~dry_run ~force:true repo_vcs ~dir:dist_build_dir >>= fun () ->
  Vcs.get ~dir:dist_build_dir () >>= fun clone_vcs ->
  let branch = Fmt.str "dune-release-dist-%a" Vcs.Tag.pp tag in
  Vcs.checkout ~dry_run clone_vcs ~branch ~commit_ish:(Tag tag) >>= fun () ->
  (if include_submodules then pull_submodules ~dry_run ~dist_build_dir
   else Ok ())
  >>= fun () ->
  distrib_prepare ~dry_run ~dist_build_dir ~version >>= fun () ->
  let exclude_paths = Fpath.Set.of_list Distrib.exclude_paths in
  Archive.tar dist_build_dir ~exclude_paths ~root ~mtime >>= fun tar ->
  distrib_archive_path p >>= fun archive ->
  Archive.bzip2 ~dry_run ~force:true ~dst:archive tar >>= fun () ->
  (if keep_dir then Ok () else Sos.delete_dir ~dry_run dist_build_dir)
  >>= fun () -> Ok archive

(* Test & build *)

type f =
  dry_run:bool ->
  dir:Fpath.t ->
  args:Cmd.t ->
  out:(OS.Cmd.run_out -> (string * OS.Cmd.run_status, Sos.error) result) ->
  ?err:Bos.OS.Cmd.run_err ->
  string list ->
  (string * OS.Cmd.run_status, Sos.error) result

let run ~dry_run ~dir ~args ~out ~default ?err pkg_names cmd =
  let pkgs = String.concat ~sep:"," pkg_names in
  let cmd = Cmd.(v "dune" % cmd % "-p" % pkgs %% args) in
  let run () = Sos.run_out ~dry_run ?err cmd ~default out in
  R.join @@ Sos.with_dir ~dry_run dir run ()

let test ~dry_run ~dir ~args ~out ?err pkg_names =
  run ~dry_run ~dir ~args ~out ~default:(Sos.out "") ?err pkg_names "runtest"

let build ~dry_run ~dir ~args ~out ?err pkg_names =
  run ~dry_run ~dir ~args ~out ~default:(Sos.out "") ?err pkg_names "build"

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
