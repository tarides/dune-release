(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup

(* Misc *)

let uri_sld uri = match Text.split_uri uri with
| None -> None
| Some (_, host, _) ->
    match List.rev (String.cuts ~sep:"." host) with
    | _ :: snd :: _ -> Some snd
    | _ -> None

let uri_append u s = match String.head ~rev:true u with
| None -> s
| Some '/' -> strf "%s%s" u s
| Some _ -> strf "%s/%s" u s

let chop_ext u = match String.cut ~rev:true ~sep:"." u with
| None -> u
| Some (u, _) -> u

let chop_git_prefix u = match String.cut ~sep:"git+" u with
| Some ("", uri) -> uri
| _ -> u

(* Package *)

type t =
  { name : string;
    version : string option;
    delegate: Cmd.t option;
    build_dir : Fpath.t option;
    drop_v: bool;
    opam : Fpath.t option;
    opam_descr : Fpath.t option;
    opam_fields : (string list String.map, R.msg) result Lazy.t;
    readmes : Fpath.t list option;
    change_logs : Fpath.t list option;
    licenses : Fpath.t list option;
    distrib: Distrib.t;
    distrib_uri : string option;
    distrib_file : Fpath.t option;
    lint_files: Fpath.t list option;
    publish_msg : string option;
    publish_artefacts : [`Distrib | `Doc | `Alt of string] list option }

let opam_fields p = Lazy.force p.opam_fields
let opam_field p f = opam_fields p >>| fun fields -> String.Map.find f fields
let opam_field_hd p f = opam_field p f >>| function
  | None | Some [] -> None
  | Some (v :: _) -> Some v

let opam_homepage p = opam_field_hd p "homepage"
let opam_doc p = opam_field_hd p "doc"
let opam_homepage_sld p = opam_homepage p >>| function
  | None -> None
  | Some uri -> match uri_sld uri with None -> None | Some sld -> Some (uri, sld)

let name p = Ok p.name

let version p = match p.version with
| Some v -> Ok v
| None -> Vcs.get () >>= fun r -> Vcs.describe ~dirty:false r

let delegate p =
  let not_found () =
    R.error_msg "No package delegate found. \
                 Try `dune-release help delegate` for more information."
  in
  match p.delegate with
  | Some cmd -> Ok (Some cmd)
  | None ->
      match OS.Env.(value "DUNE_RELEASE_DELEGATE" (some cmd) ~absent:None) with
      | Some cmd -> Ok (Some cmd)
      | None ->
          opam_homepage_sld p >>= function
          | None -> not_found ()
          | Some (_, sld) ->
              let exec = strf "%s-dune-release-delegate" sld in
              let cmd = Cmd.v exec in
              OS.Cmd.exists cmd >>= function
              | true -> Ok (Some cmd)
              | false ->
                  if exec <> "github-dune-release-delegate"
                  then not_found ()
                  else Ok None

let build_dir p = match p.build_dir with
| Some b -> Ok b
| None   -> Ok (Fpath.v "_build")

let readmes p = match p.readmes with
| Some f -> Ok f
| None  ->  Ok [Fpath.v "README.md"]

let readme p = readmes p >>= function
  | [] -> R.error_msgf "No readme file specified in the package description"
  | r :: _ -> Ok r

let opam p = match p.opam with
| Some f -> Ok f
| None   -> name p >>| fun name -> Fpath.v (name ^ ".opam")

let opam_descr p =
  let descr_file_for_opam opam =
    if Fpath.has_ext ".opam" opam then Fpath.(rem_ext opam + ".descr") else
    Fpath.(parent opam / "descr")
  in
  let read f = OS.File.read f >>= fun c -> Opam.Descr.of_string c in
  match p.opam_descr with
  | Some f -> read f
  | None ->
      opam p
      >>= fun opam -> Ok (descr_file_for_opam opam)
      >>= fun descr_file -> OS.File.exists descr_file
      >>= function
      | true ->
          Logs.info (fun m -> m "Found opam descr file %a" Fpath.pp descr_file);
          read descr_file
      | false ->
          readme p
          >>= fun readme ->
          Logs.info
            (fun m -> m "Extracting opam descr from %a" Fpath.pp readme);
          Opam.Descr.of_readme_file readme

let change_logs p = match p.change_logs with
| Some f -> Ok f
| None   -> Ok [Fpath.v "CHANGES.md"]

let change_log p = change_logs p >>= function
  | [] -> R.error_msgf "No change log specified in the package description."
  | l :: _ -> Ok l

let licenses p = match p.licenses with
| Some f -> Ok f
| None   -> Ok [Fpath.v "LICENSE.md"]

let drop_initial_v version = match String.head version with
| Some ('v' | 'V') -> String.with_index_range ~first:1 version
| None | Some _ -> version

let dev_repo p =
  opam_field_hd p "dev-repo" >>= function
  | None   -> Ok None
  | Some r ->
      let uri = chop_git_prefix r in
      match String.cut ~sep:"https://github.com/" uri with
      | Some ("", path) -> Ok (Some ("git@github.com:" ^ path))
      | _ -> Ok (Some uri)

let distrib_uri ?(raw = false) p =
  let subst_uri p uri =
    uri
    >>= fun uri -> name p
    >>= fun name -> version p
    >>= fun vers -> (if p.drop_v then Ok (drop_initial_v vers) else Ok vers)
    >>= fun version_num ->
    let defs = String.Map.(empty
                           |> add "NAME" name |> add "VERSION" vers
                           |> add "VERSION_NUM" version_num)
    in
    Pat.of_string uri >>| fun pat -> Pat.format defs pat
  in
  let not_found () =
    R.error_msg "no distribution URI found, see dune-release's API documentation."
  in
  let uri = match p.distrib_uri with
  | Some u -> Ok u
  | None ->
      opam_homepage_sld p >>= function
      | None -> not_found ()
      | Some (uri, sld) ->
          if sld <> "github"
          then (Ok (uri_append uri "releases/$(NAME)-$(VERSION_NUM).tbz"))
          else
          opam_field_hd p "dev-repo">>= function
          | None -> not_found ()
          | Some dev_repo ->
              Ok (uri_append (chop_git_prefix (chop_ext dev_repo))
                    "releases/download/$(VERSION)/$(NAME)-$(VERSION_NUM).tbz")
  in
  if raw then uri else subst_uri p uri

let distrib_filename ?(opam = false) p =
  let sep = if opam then '.' else '-' in
  name p
  >>= fun name -> version p
  >>= fun vers -> (if p.drop_v then Ok (drop_initial_v vers) else Ok vers)
  >>= fun version_num -> Fpath.of_string (strf "%s%c%s" name sep version_num)

let distrib_archive_path p =
  build_dir p
  >>= fun build_dir -> distrib_filename ~opam:false p
  >>| fun b -> Fpath.(build_dir // b + ".tbz")

let distrib_file ~dry_run p = match p.distrib_file with
| Some f -> Ok f
| None ->
    (distrib_archive_path p
     >>= fun f -> Sos.file_must_exist ~dry_run f)
    |> R.reword_error_msg
      (fun _ -> R.msgf "Did you forget to call 'dune-release distrib' ?")


let distrib_user_and_repo p =
  distrib_uri p >>= fun uri ->
  let uri_error uri =
    R.msgf "Could not derive user and repo from opam dev-repo \
            field value %a; expected the pattern \
            $SCHEME://$HOST/$USER/$REPO[.$EXT][/$DIR]" String.dump uri
  in
  match Text.split_uri ~rel:true uri with
  | None -> Error (uri_error uri)
  | Some (_, _, path) ->
      if path = "" then Error (uri_error uri) else
      match String.cut ~sep:"/" path with
      | None -> Error (uri_error uri)
      | Some (user, path) ->
          let repo = match String.cut ~sep:"/" path with
          | None -> path
          | Some (repo, _) -> repo
          in
          begin
            Fpath.of_string repo
            >>= fun repo -> Ok (user, Fpath.(to_string @@ rem_ext repo))
          end
          |> R.reword_error_msg (fun _ -> uri_error uri)

let doc_uri p = opam_field_hd p "doc" >>| function
  | None     -> ""
  | Some uri -> uri

let doc_user_repo_and_path p =
  doc_uri p >>= fun uri ->
  (* Parses the $PATH of $SCHEME://$HOST/$REPO/$PATH *)
  let uri_error uri =
    R.msgf "Could not derive publication directory $PATH from opam doc \
            field value %a; expected the pattern \
            $SCHEME://$USER.github.io/$REPO/$PATH" String.dump uri
  in
  match Text.split_uri ~rel:true uri with
  | None -> Error (uri_error uri)
  | Some (_, host, path) ->
      if path = "" then Error (uri_error uri) else
      (match String.cut ~sep:"." host with
      | Some (user, g) when String.equal g "github.io" -> Ok user
      | _ -> Error (uri_error uri))
      >>= fun user ->
      match String.cut ~sep:"/" path with
      | None -> Error (uri_error uri)
      | Some (repo, "") -> Ok (user, repo, Fpath.v ".")
      | Some (repo, path) ->
          (Fpath.of_string path >>| fun p -> user, repo, Fpath.rem_empty_seg p)
          |> R.reword_error_msg (fun _ -> uri_error uri)

let publish_msg p = match p.publish_msg with
| Some msg -> Ok msg
| None ->
    change_log p
    >>= fun change_log -> Text.change_log_file_last_entry change_log
    >>= fun (_, (_, txt)) -> Ok (strf "CHANGES:\n\n%s\n" (String.trim txt))

let publish_artefacts p = match p.publish_artefacts with
| Some arts -> Ok arts
| None -> Ok [`Doc; `Distrib]

let infer_name () =
  let opam_files =
    Sys.readdir "."
    |> Array.to_list
    |> List.filter (String.is_suffix ~affix:".opam")
  in
  if opam_files = [] then begin
    Logs.err (fun m -> m "no <package>.opam files found.");
    exit 1
  end;
  let package_names =
    let suffix_len = String.length ".opam" in
    List.map (fun s ->
        String.with_range s ~len:(String.length s - suffix_len)
      ) opam_files
  in
  let name =
    let shortest =
      match package_names with
      | [] -> assert false
      | first :: rest ->
          List.fold_left (fun acc s ->
              if String.length s < String.length acc
              then s
              else acc
            ) first rest
    in
    if List.for_all (String.is_prefix ~affix:shortest) package_names
    then shortest
    else begin
      Logs.err (fun m ->
          m "cannot determine name automatically. Use `-p <name>`");
      exit 1
    end
  in
  name

let v ~dry_run
    ?name ?version ?delegate ?(drop_v=true) ?build_dir ?opam:opam_file ?opam_descr
    ?readme ?change_log ?license ?distrib_uri ?distrib_file ?publish_msg
    ?publish_artefacts ?(distrib=Distrib.v ()) ?(lint_files = Some []) ()
  =
  let name = match name with None -> infer_name () | Some v -> v in
  let readmes = match readme with Some r -> Some [r] | None -> None in
  let change_logs = match change_log with Some c -> Some [c] | None -> None in
  let licenses = match license with Some l -> Some [l] | None -> None in
  let rec opam_fields = lazy (opam p >>= fun o -> Opam.File.fields ~dry_run o)
  and p =
    { name; version; delegate; drop_v; build_dir; opam = opam_file; opam_descr;
      opam_fields; readmes; change_logs; licenses; distrib_uri; distrib_file;
      publish_msg; publish_artefacts; distrib; lint_files }
  in
  p

(* Distrib *)

let distrib_version_opam_files ~dry_run p ~version =
  let version = if p.drop_v then drop_initial_v version else version in
  opam p
  >>= fun file -> OS.File.read file
  >>= fun o -> Ok (Fmt.strf "version: \"%s\"\n%s" version o)
  >>= fun o -> Sos.write_file ~dry_run file o

let distrib_prepare ~dry_run p ~dist_build_dir ~name ~version ~opam =
  let d = p.distrib in
  let ws = Distrib.watermarks d in
  let ws_defs = Distrib.define_watermarks ws ~dry_run ~name ~version ~opam in
  Sos.with_dir ~dry_run dist_build_dir (fun () ->
      Distrib.files_to_watermark d ()
      >>= fun files -> Distrib.watermark_files ws_defs files
      >>= fun () -> distrib_version_opam_files ~dry_run p ~version
      >>= fun () -> Distrib.massage d ()
      >>= fun () -> Distrib.exclude_paths d ()
    ) ()
  |> R.join

let distrib_archive ~dry_run p ~keep_dir =
  Archive.ensure_bzip2 ()
  >>= fun () -> name p
  >>= fun name -> build_dir p
  >>= fun build_dir -> version p
  >>= fun version -> opam p
  >>= fun opam -> distrib_filename p
  >>= fun root -> Ok Fpath.(build_dir // root + ".build")
  >>= fun dist_build_dir -> Sos.delete_dir ~dry_run ~force:true dist_build_dir
  >>= fun () -> Vcs.get ()
  >>= fun repo -> Vcs.commit_id repo ~dirty:false
  >>= fun head -> Vcs.commit_ptime_s repo ~commit_ish:head
  >>= fun mtime -> Vcs.clone ~dry_run ~force:true repo ~dir:dist_build_dir
  >>= fun () -> Vcs.get ~dir:dist_build_dir ()
  >>= fun clone -> Ok (Fmt.strf "dune-release-dist-%s" head)
  >>= fun branch -> Vcs.checkout ~dry_run clone ~branch ~commit_ish:head
  >>= fun () -> distrib_prepare ~dry_run p ~dist_build_dir ~name ~version ~opam
  >>= fun exclude_paths ->
  let exclude_paths = Fpath.Set.of_list exclude_paths in
  Archive.tar dist_build_dir ~exclude_paths ~root ~mtime
  >>= fun tar -> distrib_archive_path p
  >>= fun archive -> Archive.bzip2 ~dry_run ~force:true ~dst:archive tar
  >>= fun () ->
  (if keep_dir then Ok () else Sos.delete_dir ~dry_run dist_build_dir)
  >>= fun () -> Ok archive

(* Test & build *)

type f =
  dry_run:bool ->
  dir:Fpath.t ->
  args:Cmd.t ->
  out:(OS.Cmd.run_out -> (string * OS.Cmd.run_status, Sos.error) result) ->
  t -> (string * OS.Cmd.run_status, Sos.error) result

let run ~dry_run ~dir ~args ~out ~default p cmd =
  let name = p.name in
  let cmd = Cmd.(v "jbuilder" % cmd % "-p" % name %% args) in
  let run () = Sos.run_out ~dry_run cmd ~default out in
  R.join @@ Sos.with_dir ~dry_run dir run ()

let test ~dry_run ~dir ~args ~out p =
  run ~dry_run ~dir ~args ~out ~default:(Sos.out "") p "runtest"

let build ~dry_run ~dir ~args ~out p =
  run ~dry_run ~dir ~args ~out ~default:(Sos.out "") p "build"

let clean ~dry_run ~dir ~args ~out p =
  run ~dry_run ~dir ~args ~out ~default:(Sos.out "") p "clean"

(* Lint *)

let pp_path = Text.Pp.path
let pp_status = Text.Pp.status

let lint_disabled test =
  Logs.info (fun m -> m ~header:"LINT" "Package@ disabled@ %a." Fmt.text test);
  0

let std_files p =
  let v = function Some x -> x | None -> [] in
  v p.readmes @ v p.licenses @
  v p.change_logs @ match p.opam with Some v -> [v] | None -> []

let lint_files p = match p.lint_files with
| None (* disabled *) -> None
| Some fs -> Some (List.rev_append (std_files p) fs)

let lint_std_files ~dry_run p =
  let lint_exists file errs =
    let report exists =
      let status, errs = if exists then `Ok, errs else `Fail, errs + 1 in
      Logs.app (fun m ->
          m "%a @[File %a@ is@ present.@]" pp_status status pp_path file);
      errs
    in
    (Sos.file_exists ~dry_run file >>= fun exists -> Ok (report exists))
    |> Logs.on_error_msg ~use:(fun () -> errs + 1)
  in
  begin
    match lint_files p with
    | None -> Ok (lint_disabled "standard files linting")
    | Some files ->
        let files = Fpath.Set.of_list files in
        Ok (Fpath.Set.fold lint_exists files 0)
  end
  |> Logs.on_error_msg ~use:(fun () -> 1)

let lint_file_with_cmd ~dry_run file_kind ~cmd file errs handle_exit =
  let run_linter cmd file ~exists =
    if not (exists || dry_run) then
      Ok (`Fail (strf "%a: No such file" Fpath.pp file))
    else
    Sos.run_out ~dry_run ~err:OS.Cmd.err_run_out Cmd.(cmd % p file)
      ~default:(Sos.out "") OS.Cmd.out_string
    >>| fun (out, status) -> handle_exit (snd status) out
  in
  begin
    OS.File.exists file
    >>= fun exists -> run_linter cmd file ~exists
    >>| function
    | `Ok ->
        Logs.app
          (fun m -> m "%a @[lint@ %s %a.@]"
              pp_status `Ok file_kind pp_path file);
        errs
    | `Fail msgs ->
        Logs.app
          (fun m -> m "%a @[<v>@[lint@ %s %a:@]@,@[%a messages:@]@,%a@]"
              pp_status `Fail file_kind pp_path file Cmd.pp cmd Fmt.lines msgs);
        errs + 1
  end
  |> Logs.on_error_msg ~use:(fun () -> errs + 1)

let lint_opams ~dry_run p =
  let tool_version = Lazy.force Opam.version in
  let lint opam_version =
    let args = match opam_version, Lazy.force Opam.version with
    | Some ["1.2"], `v2 -> Cmd.v "--warn=-21-32-48"
    | _ -> Cmd.empty
    in
    opam p >>= fun opam ->
    (* We first run opam lint with -s and if there's something beyond 5
       we rerun it without it for the error messages. It's ugly since 5
       will still but opam lint's cli is broken. *)
    let cmd = Cmd.(Opam.cmd % "lint" %% args) in
    let handle_exit file status out = match status, out with
    | `Exited 0,
      ("" | "5" (* dirname version vs opam file version *)) -> `Ok
    | _ ->
        let err = OS.Cmd.err_run_out in
        let cmd = Cmd.(cmd % p file)  in
        let default = Sos.out "" in
        match Sos.run_out ~dry_run ~err cmd ~default OS.Cmd.out_string with
        | Ok (out, _     ) -> `Fail out
        | Error (`Msg out) -> `Fail out
    in
    let cmd = Cmd.(cmd % "-s") in
    let d =
      lint_file_with_cmd ~dry_run "opam file" ~cmd opam 0 (handle_exit opam)
    in
    (* lint fields *)
    if dry_run then Ok 0
    else (
      doc_user_repo_and_path p >>= fun _ ->
      distrib_user_and_repo p >>| fun _ ->
      d
    )
  in
  Logs.on_error_msg ~use:(fun () -> 1) (
    (* remove opam.1.2-related warnings *)
    opam_field p "opam-version" >>= fun opam_version ->
    match opam_version, tool_version with
    | Some ["2.0"], `v1_2_2 ->
        Logs.app (fun m ->
            m "Skipping opam lint as `opam-version` field is \"2.0\" \
               while `opam --version` is 1.2.2");
        Ok 0
    | _ -> lint opam_version)

type lint = [ `Std_files | `Opam ]

let lints =
  [`Std_files, lint_std_files;
   `Opam, lint_opams ]

let lint_all = List.map fst lints

let lint ~dry_run ~dir p todo =
  let lint pkg =
    let do_lint acc (l, f) = acc + if List.mem l todo then f ~dry_run pkg else 0 in
    match List.fold_left do_lint 0 lints with
    | 0 ->
        Logs.app (fun m -> m "%a lint@ %a %a"
                     pp_status `Ok pp_path dir
                     (Fmt.styled_unit `Green "success") ()); 0
    | n ->
        Logs.app (fun m -> m "%a lint@ %a@ %a:@ %d@ errors."
                     pp_status `Fail pp_path dir
                     (Fmt.styled_unit `Red "failure") () n); 1
  in
  Sos.with_dir ~dry_run dir lint p

(* tags *)

let extract_version change_log =
  Text.change_log_file_last_entry change_log
  >>= fun (version, _) -> Ok version

let tag pkg = change_log pkg >>= fun cl -> extract_version cl

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
