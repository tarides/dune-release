open Bos_setup

type t = [ `Std_files | `Opam ]

let report_status status f =
  Logs.app (fun l ->
      f (fun ?header ?tags fmt ->
          l ?header ?tags ("%a " ^^ fmt) Text.Pp.status status))

type cmds = {
  distrib : bool;
  publish : bool;
  opam_pkg : bool;
  opam_submit : bool;
}

type status = OK | KO

type linting_check = {
  name : string;
  msg_ok : string;
  msg_ko : string;
  required_for_steps : cmds;
  check : dry_run:bool -> Pkg.t -> bool;
}

type check_status = {
  distrib : status;
  publish : status;
  opam_pkg : status;
  opam_submit : status;
}

let pp_status fmt { distrib; publish; opam_pkg; opam_submit } =
  let pp fmt = function
    | OK -> Format.fprintf fmt "OK"
    | KO -> Format.fprintf fmt "KO"
  in
  Format.fprintf fmt
    "[distrib:%a]@,[publish:%a]@,[opam-pkg:%a]@,[opam-submit:%a]" pp distrib pp
    publish pp opam_pkg pp opam_submit

let check ~dry_run pkg { name; msg_ok; msg_ko; required_for_steps; check } =
  let status =
    if check ~dry_run pkg then
      { distrib = OK; publish = OK; opam_pkg = OK; opam_submit = OK }
    else
      {
        distrib = (if required_for_steps.distrib then KO else OK);
        publish = (if required_for_steps.publish then KO else OK);
        opam_pkg = (if required_for_steps.opam_pkg then KO else OK);
        opam_submit = (if required_for_steps.opam_submit then KO else OK);
      }
  in
  match status with
  | { distrib = OK; publish = OK; opam_pkg = OK; opam_submit = OK } ->
      report_status `Ok (fun m ->
          m "@[@<10>%s@ @<10>%s@ %a.@]" name msg_ok pp_status status);
      0
  | _ ->
      report_status `Fail (fun m ->
          m "@[@<10>%s@ @<10>%s@ %a.@]" name msg_ko pp_status status);
      1

let all_checks ~dry_run pkg checks =
  let go acc x = acc + check ~dry_run pkg x in
  List.fold_left go 0 checks

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

let std_files_linting_checks =
  List.map
    (fun { generic_name; get_path } ->
      {
        name = generic_name;
        msg_ok = "is present";
        msg_ko = "is missing";
        required_for_steps =
          {
            distrib = true;
            publish = true;
            opam_pkg = true;
            opam_submit = true;
          };
        check =
          (fun ~dry_run pkg ->
            match
              get_path pkg >>= function
              | [] -> Ok `Fail
              | path :: _ ->
                  Sos.file_exists ~dry_run path >>= fun exists ->
                  Ok (if exists then `Ok else `Fail)
            with
            | Ok `Ok -> true
            | Ok `Fail -> false
            | Error _ -> false);
      })
    std_files

let lint_std_files ~dry_run pkg =
  all_checks ~dry_run pkg std_files_linting_checks

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
      report_status `Ok msgf;
      0
  | Error _ as err ->
      report_status `Fail msgf;
      Logs.on_error_msg ~use:(fun () -> 1) err

let pp_field = Fmt.(styled `Bold string)

let lint_opam_doc pkg =
  ( match Pkg.doc_uri pkg with
  | Error _ | Ok "" ->
      report_status `Ok (fun l ->
          l "Skipping doc field linting, no doc field found")
  | Ok _ ->
      let pass = R.is_ok (Pkg.doc_user_repo_and_path pkg) in
      let status = if pass then `Ok else `Fail in
      let verdict = if pass then "can" else "cannot" in
      report_status status (fun l ->
          l "opam field %a %s be parsed by dune-release" pp_field "doc" verdict)
  );
  0

let lint_opam_home_and_dev pkg =
  lint_res
    ~msgf:(fun l ->
      l "opam fields %a and %a can be parsed by dune-release" pp_field
        "homepage" pp_field "dev-repo")
    (Pkg.infer_distrib_uri pkg >>= Pkg.distrib_user_and_repo)

let lint_opam_github_fields pkg = lint_opam_doc pkg + lint_opam_home_and_dev pkg

let opam_lint_cmd ~opam_file_version ~opam_tool_version =
  let lint_older_format =
    match (opam_file_version, opam_tool_version) with
    | Some "1.2", Opam.Version.V2 -> true
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
      | Ok (out, _) | Error (`Msg out) -> `Fail out )

let check_has_description ~opam_file pkg =
  Pkg.opam_field_hd pkg "description" >>= function
  | None ->
      R.error_msgf "%a does not have a 'description' field." Fpath.pp opam_file
  | Some _ -> Ok ()

let lint_descr ~opam_file pkg =
  lint_res
    ~msgf:(fun l -> l "opam field %a is present" pp_field "description")
    (check_has_description ~opam_file pkg)

let opam_lint ~dry_run ~opam_file_version ~opam_tool_version opam_file =
  let base_lint_cmd = opam_lint_cmd ~opam_file_version ~opam_tool_version in
  let short_lint_cmd = Cmd.(base_lint_cmd % "-s") in
  let verbose_lint_cmd = base_lint_cmd in
  lint_file_with_cmd ~dry_run ~file_kind:"opam file" ~cmd:short_lint_cmd
    ~handle_exit:(handle_opam_lint_exit ~dry_run ~verbose_lint_cmd ~opam_file)
    opam_file 0

let extra_opam_lint ~opam_file_version ~opam_file pkg =
  let is_2_0_format =
    match opam_file_version with Some "2.0" -> true | _ -> false
  in
  let descr_err = if is_2_0_format then lint_descr ~opam_file pkg else 0 in
  let github_field_errs = lint_opam_github_fields pkg in
  descr_err + github_field_errs

let lint_opam ~dry_run pkg =
  Lazy.force Opam.Version.cli >>= fun opam_tool_version ->
  Pkg.opam_field_hd pkg "opam-version" >>= fun opam_file_version ->
  match (opam_file_version, opam_tool_version) with
  | Some "2.0", Opam.Version.V1_2_2 ->
      App_log.status (fun l ->
          l
            "Skipping opam lint as `opam-version` field is \"2.0\" while `opam \
             --version` is 1.2.2");
      Ok 0
  | _ ->
      Pkg.opam pkg >>= fun opam_file ->
      let opam_lint_errors =
        opam_lint ~dry_run ~opam_file_version ~opam_tool_version opam_file
      in
      let extra_errors = extra_opam_lint ~opam_file_version ~opam_file pkg in
      Ok (opam_lint_errors + extra_errors)

let lint_opam ~dry_run pkg =
  Logs.on_error_msg ~use:(fun () -> 1) (lint_opam ~dry_run pkg)

let t_to_fun = [ (`Std_files, lint_std_files); (`Opam, lint_opam) ]

let all = List.map fst t_to_fun

let apply_lint ~dry_run t pkg =
  let f = List.assoc t t_to_fun in
  f ~dry_run pkg

let lint_pkg ~dry_run ~dir pkg todo =
  let lint pkg =
    let do_lint acc t =
      let errs = apply_lint t ~dry_run pkg in
      acc + errs
    in
    let total_errs = List.fold_left do_lint 0 todo in
    match total_errs with
    | 0 ->
        Logs.app (fun m ->
            m "%a lint %a %a" Text.Pp.status `Ok Text.Pp.path dir
              (Fmt.styled_unit `Green "success")
              ());
        0
    | n ->
        Logs.app (fun m ->
            m "%a lint %a %a: %d errors." Text.Pp.status `Fail Text.Pp.path dir
              (Fmt.styled_unit `Red "failure")
              () n);
        1
  in
  Sos.with_dir ~dry_run dir lint pkg
