open Bos_setup

type t = [ `Std_files | `Opam ]

type std_file = {
  generic_name : string;
  get_path : Pkg.t -> (Fpath.t list, R.msg) result;
}

let std_files =
  [
    { generic_name = "README"; get_path = Pkg.readmes };
    { generic_name = "LICENSE"; get_path = Pkg.licenses };
    { generic_name = "CHANGES"; get_path = Pkg.change_logs };
    {
      generic_name = "opam";
      get_path = (fun pkg -> Pkg.opam pkg >>| fun o -> [ o ]);
    };
  ]

let status_to_presence = function
  | `Ok -> "present"
  | `Fail | `Warn -> "missing"

let lint_exists_file ~dry_run { generic_name; get_path } pkg =
  let status =
    get_path pkg >>= function
    | [] -> Ok `Fail
    | path :: _ ->
        Sos.file_exists ~dry_run path >>= fun exists ->
        Ok (if exists then `Ok else `Fail)
  in
  status >>= fun status ->
  let presence = status_to_presence status in
  App_log.report_status status (fun m ->
      m "@[File %a@ is@ %s.@]" Text.Pp.path (Fpath.v generic_name) presence);
  let err_count = match status with `Ok -> 0 | `Fail -> 1 in
  Ok err_count

let lint_std_files ~dry_run pkg =
  let go errs file =
    let new_err =
      Logs.on_error_msg ~use:(fun () -> 1) (lint_exists_file ~dry_run file pkg)
    in
    errs + new_err
  in
  List.fold_left go 0 std_files

let lint_res ~msgf = function
  | Ok _ ->
      App_log.report_status `Ok msgf;
      0
  | Error _ as err ->
      App_log.report_status `Fail msgf;
      Logs.on_error_msg ~use:(fun () -> 1) err

let pp_field = Fmt.(styled `Bold string)

let lint_opam_doc pkg =
  (match Pkg.doc_uri pkg with
  | Error _ | Ok "" ->
      App_log.report_status `Ok (fun l ->
          l "Skipping doc field linting, no doc field found")
  | Ok _ ->
      let pass = R.is_ok (Pkg.github_doc_owner_repo_and_path pkg) in
      let status = if pass then `Ok else `Fail in
      let verdict = if pass then "can" else "cannot" in
      App_log.report_status status (fun l ->
          l "opam field %a %s be parsed by dune-release" pp_field "doc" verdict));
  0

let lint_opam_home_and_dev pkg =
  lint_res
    ~msgf:(fun l ->
      l "opam fields %a and %a can be parsed by dune-release" pp_field
        "homepage" pp_field "dev-repo")
    (Pkg.infer_github_repo pkg)

let lint_opam_github_fields pkg = lint_opam_doc pkg + lint_opam_home_and_dev pkg

let lint () =
  let opam_files_in_dir d =
    match OpamPinned.files_in_source d with
    | [] ->
        OpamConsole.warning "No opam files found in %s"
          (OpamFilename.Dir.to_string d);
        []
    | l -> List.map (fun (_name, f, _) -> Some f) l
  in
  let files = opam_files_in_dir (OpamFilename.cwd ()) in
  let msg = OpamConsole.msg in
  let json = None in
  let err, json =
    List.fold_left
      (fun (err, json) opam_f ->
        try
          let warnings, _ =
            match opam_f with
            | Some f ->
                OpamFileTools.lint_file ~check_upstream:false
                  ~handle_dirname:true f
            | None ->
                OpamFileTools.lint_channel ~check_upstream:false
                  ~handle_dirname:false
                  (OpamFile.make (OpamFilename.of_string "-"))
                  stdin
          in
          let failed =
            List.exists (function _, `Error, _ -> true | _ -> false) warnings
          in
          if warnings = [] then
            msg "%s%s\n"
              (OpamStd.Option.to_string
                 (fun f -> OpamFile.to_string f ^ ": ")
                 opam_f)
              (OpamConsole.colorise `green "Linting passed.")
          else
            msg "%s%s\n%s\n"
              (OpamStd.Option.to_string
                 (fun f -> OpamFile.to_string f ^ ": ")
                 opam_f)
              (if failed then OpamConsole.colorise `red "Errors."
              else OpamConsole.colorise `yellow "Warnings.")
              (OpamFileTools.warns_to_string warnings);
          let json =
            OpamStd.Option.map
              (OpamStd.List.cons
                 (OpamFileTools.warns_to_json
                    ?filename:(OpamStd.Option.map OpamFile.to_string opam_f)
                    warnings))
              json
          in
          (err || failed, json)
        with
        | Parsing.Parse_error | OpamLexer.Error _ | OpamPp.Bad_version _
        | OpamPp.Bad_format _
        ->
          msg "File format error\n";
          (true, json))
      (false, json) files
  in
  OpamStd.Option.iter (fun json -> OpamJson.append "lint" (`A json)) json;
  if err then 1 else 0

let check_has_synopsis ~opam_file pkg =
  Pkg.opam_field_hd pkg "synopsis" >>= function
  | None ->
      R.error_msgf "%a does not have a 'synopsis' field." Fpath.pp opam_file
  | Some _ -> Ok ()

let lint_descr ~opam_file pkg =
  lint_res
    ~msgf:(fun l -> l "opam field %a is present" pp_field "synopsis")
    (check_has_synopsis ~opam_file pkg)

let extra_opam_lint ~opam_file_version ~opam_file pkg =
  let is_2_0_format =
    match opam_file_version with
    | Some "2.0" -> true
    | _ ->
        let _ = Deprecate.Opam_1_x.remove_me in
        false
  in
  let descr_err = if is_2_0_format then lint_descr ~opam_file pkg else 0 in
  let github_field_errs = lint_opam_github_fields pkg in
  descr_err + github_field_errs

let opam_file_format_major opam_file_version =
  match String.cut ~sep:"." opam_file_version with
  | Some (major, _) -> int_of_string_opt major
  | _ -> None

let lint_opam ~dry_run:_ pkg =
  Pkg.opam_field_hd pkg "opam-version" >>= fun opam_file_version ->
  (match Stdext.Option.bind ~f:opam_file_format_major opam_file_version with
  | Some 1 ->
      App_log.unhappy (fun l -> l "%s" Deprecate.Opam_1_x.file_format_warning)
  | _ -> ());
  Pkg.opam pkg >>= fun opam_file ->
  let opam_lint_errors = lint () in
  let extra_errors = extra_opam_lint ~opam_file_version ~opam_file pkg in
  Ok (opam_lint_errors + extra_errors)

let lint_opam ~dry_run pkg =
  Logs.on_error_msg ~use:(fun () -> 1) (lint_opam ~dry_run pkg)

let t_to_fun = [ (`Std_files, lint_std_files); (`Opam, lint_opam) ]
let all = List.map fst t_to_fun

let apply_lint ~dry_run t pkg =
  let f = List.assoc t t_to_fun in
  f ~dry_run pkg

let pp_pkg_name = Fmt.(styled `Bold string)

let lint_pkg ~dry_run ~dir ~pkg_name pkg todo =
  let lint pkg =
    let do_lint acc t =
      let errs = apply_lint t ~dry_run pkg in
      acc + errs
    in
    let total_errs = List.fold_left do_lint 0 todo in
    match total_errs with
    | 0 ->
        Logs.app (fun m ->
            m "%a lint of %a and package %a %a" Text.Pp.status `Ok Text.Pp.path
              dir pp_pkg_name pkg_name
              (Fmt.styled `Green Fmt.(any "success"))
              ());
        0
    | n ->
        Logs.app (fun m ->
            m "%a lint of %a and package %a %a: %d errors." Text.Pp.status `Fail
              Text.Pp.path dir pp_pkg_name pkg_name
              (Fmt.styled `Red Fmt.(any "failure"))
              () n);
        1
  in
  Sos.with_dir ~dry_run dir lint pkg

let lint_packages ~dry_run ~dir ~todo pkg pkg_names =
  Pkg.infer_pkg_names dir pkg_names >>= fun pkg_names ->
  List.fold_left
    (fun acc name ->
      acc >>= fun acc ->
      let pkg = Pkg.with_name pkg name in
      App_log.blank_line ();
      App_log.status (fun m ->
          m "Performing lint for package %a in %a" pp_pkg_name name Text.Pp.path
            dir);
      lint_pkg ~dry_run ~dir ~pkg_name:name pkg todo >>= fun n -> Ok (acc + n))
    (Ok 0) pkg_names
