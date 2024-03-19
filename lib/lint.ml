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

let lint_file_with_cmd ~dry_run ~file_kind ~cmd ~handle_exit file errs =
  let run_linter cmd file ~exists =
    if not (exists || dry_run) then
      Ok (`Fail (strf "%a: No such file" Fpath.pp file))
    else
      Sos.run_out ~dry_run ~err:OS.Cmd.err_run_out
        Cmd.(cmd % p file)
        ~default:(Sos.out "") OS.Cmd.out_string
      >>| fun (out, status) -> handle_exit (snd status) out
  in
  Logs.on_error_msg
    ~use:(fun () -> errs + 1)
    ( OS.File.exists file >>= fun exists ->
      run_linter cmd file ~exists >>| function
      | `Ok ->
          Logs.app (fun m ->
              m "%a @[lint@ %s %a.@]" Text.Pp.status `Ok file_kind Text.Pp.path
                file);
          errs
      | `Fail msgs ->
          Logs.app (fun m ->
              m "%a @[<v>@[lint@ %s %a:@]@,@[%a messages:@]@,%a@]"
                Text.Pp.status `Fail file_kind Text.Pp.path file Cmd.pp cmd
                Fmt.lines msgs);
          errs + 1 )

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

let opam_lint_cmd ~opam_file_version =
  let lint_older_format =
    match opam_file_version with
    | Some "1.2" ->
        let _ = Deprecate.Opam_1_x.remove_me in
        true
    | _ -> false
  in
  Cmd.(Opam.cmd % "lint" %% on lint_older_format (v "--warn=-21-32-48"))

(* We first run opam lint with -s and if there's something beyond 5
   we rerun it without it for the error messages. It's ugly since 5
   will still but opam lint's cli is broken. *)
let handle_opam_lint_exit ~dry_run ~verbose_lint_cmd ~opam_file status output =
  match (status, output) with
  | `Exited 0, ("" | "5") -> `Ok
  | _ -> (
      let default = Sos.out "" in
      let err = OS.Cmd.err_run_out in
      let cmd = Cmd.(verbose_lint_cmd % p opam_file) in
      let verbose_lint_output =
        Sos.run_out ~dry_run ~err ~default cmd OS.Cmd.out_string
      in
      match verbose_lint_output with
      | Ok (out, _) | Error (`Msg out) -> `Fail out)

let check_has_synopsis ~opam_file pkg =
  Pkg.opam_field_hd pkg "synopsis" >>= function
  | None ->
      R.error_msgf "%a does not have a 'synopsis' field." Fpath.pp opam_file
  | Some _ -> Ok ()

let lint_descr ~opam_file pkg =
  lint_res
    ~msgf:(fun l -> l "opam field %a is present" pp_field "synopsis")
    (check_has_synopsis ~opam_file pkg)

let opam_lint_with_cmd ~dry_run ~opam_file_version opam_file =
  let base_lint_cmd = opam_lint_cmd ~opam_file_version in
  let short_lint_cmd = Cmd.(base_lint_cmd % "-s") in
  let verbose_lint_cmd = base_lint_cmd in
  lint_file_with_cmd ~dry_run ~file_kind:"opam file" ~cmd:short_lint_cmd
    ~handle_exit:(handle_opam_lint_exit ~dry_run ~verbose_lint_cmd ~opam_file)
    opam_file 0

let opam_lint_impl ~dry_run ~opam_file_version opam_file =
  ref (opam_lint_with_cmd ~dry_run ~opam_file_version opam_file)

let opam_lint ~dry_run ~opam_file_version opam_file =
  !(opam_lint_impl ~dry_run ~opam_file_version opam_file)

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

let lint_opam ~dry_run pkg =
  Pkg.opam_field_hd pkg "opam-version" >>= fun opam_file_version ->
  (match Stdext.Option.bind ~f:opam_file_format_major opam_file_version with
  | Some 1 ->
      App_log.unhappy (fun l -> l "%s" Deprecate.Opam_1_x.file_format_warning)
  | _ -> ());
  Pkg.opam pkg >>= fun opam_file ->
  let opam_lint_errors = opam_lint ~dry_run ~opam_file_version opam_file in
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
