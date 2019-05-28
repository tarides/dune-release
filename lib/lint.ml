open Bos_setup

type t = [ `Std_files | `Opam ]

let lint_files pkg =
  Pkg.readmes pkg >>= fun readmes ->
  Pkg.licenses pkg >>= fun licenses ->
  Pkg.change_logs pkg >>= fun changelogs ->
  Pkg.opam pkg >>| fun opam ->
  readmes
  @ licenses
  @ changelogs
  @ [opam]

let lint_std_files ~dry_run pkg =
  let lint_exists file errs =
    let report exists =
      let status, errs = if exists then `Ok, errs else `Fail, errs + 1 in
      Logs.app (fun m -> m "%a @[File %a@ is@ present.@]" Text.Pp.status status Text.Pp.path file);
      errs
    in
    (Sos.file_exists ~dry_run file >>= fun exists -> Ok (report exists))
    |> Logs.on_error_msg ~use:(fun () -> errs + 1)
  in
  begin
    lint_files pkg >>= fun files ->
    let files = Fpath.Set.of_list files in
    Ok (Fpath.Set.fold lint_exists files 0)
  end
  |> Logs.on_error_msg ~use:(fun () -> 1)

let lint_file_with_cmd ~dry_run ~file_kind ~cmd ~handle_exit file errs =
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
        Logs.app (fun m -> m "%a @[lint@ %s %a.@]" Text.Pp.status `Ok file_kind Text.Pp.path file);
        errs
    | `Fail msgs ->
        Logs.app
          (fun m -> m "%a @[<v>@[lint@ %s %a:@]@,@[%a messages:@]@,%a@]"
              Text.Pp.status `Fail file_kind Text.Pp.path file Cmd.pp cmd Fmt.lines msgs);
        errs + 1
  end
  |> Logs.on_error_msg ~use:(fun () -> errs + 1)

let lint_res res = Logs.on_error_msg ~use:(fun () -> 1) (res >>| fun _ -> 0)

let lint_opam_github_fields pkg =
  lint_res (Pkg.doc_user_repo_and_path pkg)
  + lint_res (Pkg.distrib_user_and_repo pkg)

let opam_lint_cmd ~opam_file_version ~opam_tool_version =
  let lint_old_format =
    match opam_file_version, opam_tool_version with
    | Some "1.2", `v2 -> true
    | _ -> false
  in
  Cmd.(Opam.cmd % "lint" %% (on lint_old_format (v "--warn=-21-32-48")))

(* We first run opam lint with -s and if there's something beyond 5
   we rerun it without it for the error messages. It's ugly since 5
   will still but opam lint's cli is broken. *)
let handle_opam_lint_exit ~dry_run ~verbose_lint_cmd ~opam_file status output =
  match status, output with
  | `Exited 0, ("" | "5") -> `Ok
  | _ ->
      let default = Sos.out "" in
      let err = OS.Cmd.err_run_out in
      let cmd = Cmd.(verbose_lint_cmd % p opam_file) in
      let verbose_lint_output = Sos.run_out ~dry_run ~err ~default cmd OS.Cmd.out_string in
      match verbose_lint_output with
      | Ok (out, _)
      | Error (`Msg out) -> `Fail out

let lint_opam_file ~dry_run ~base_lint_cmd opam_file =
  let short_lint_cmd = Cmd.(base_lint_cmd % "-s") in
  let verbose_lint_cmd = base_lint_cmd in
  lint_file_with_cmd
    ~dry_run
    ~file_kind:"opam file"
    ~cmd:short_lint_cmd
    ~handle_exit:(handle_opam_lint_exit ~dry_run ~verbose_lint_cmd ~opam_file)
    opam_file
    0

let check_has_description ~opam_file pkg =
  Pkg.opam_field_hd pkg "description" >>= function
  | None -> R.error_msgf "%a does not have a 'description' field." Fpath.pp opam_file
  | Some _ -> Ok ()

let check_has_non_empty_synopsis ~opam_file pkg =
  Pkg.opam_field_hd pkg "synopsis" >>= function
  | None
  | Some "" -> R.error_msgf "%a does not have a 'synopsis' field" Fpath.pp opam_file
  | Some _ -> Ok ()

let lint_descr_and_synopsis ~opam_file pkg =
  lint_res (check_has_non_empty_synopsis ~opam_file pkg)
  + lint_res (check_has_description ~opam_file pkg)

let lint_opam ~dry_run pkg =
  let opam_tool_version = Lazy.force Opam.version in
  let lint opam_file_version =
    let base_lint_cmd = opam_lint_cmd ~opam_file_version ~opam_tool_version in
    Pkg.opam pkg >>= fun opam ->
    let errs = lint_opam_file ~dry_run ~base_lint_cmd opam in
    if dry_run then
      Ok 0
    else
      let github_field_errs = lint_opam_github_fields pkg in
      Ok (github_field_errs + errs)
  in
  Logs.on_error_msg ~use:(fun () -> 1) (
    (* remove opam.1.2-related warnings *)
    Pkg.opam_field_hd pkg "opam-version" >>= fun opam_version ->
    match opam_version, opam_tool_version with
    | Some "2.0", `v1_2_2 ->
        Logs.app (fun m ->
            m "Skipping opam lint as `opam-version` field is \"2.0\" \
               while `opam --version` is 1.2.2");
        Ok 0
    | Some "2.0", _ ->
        (* check that the descr and synopsis fields are not empty *)
        Pkg.opam pkg >>= fun opam_file ->
        let descr_and_sin_errs = lint_descr_and_synopsis ~opam_file pkg in
        lint opam_version >>| fun opam_lint_errs ->
        descr_and_sin_errs + opam_lint_errs
    | _ -> lint opam_version)

let t_to_fun =
  [`Std_files, lint_std_files;
   `Opam, lint_opam ]

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
        Logs.app
          (fun m -> m "%a lint %a %a" Text.Pp.status `Ok Text.Pp.path dir (Fmt.styled_unit `Green "success") ());
        0
    | n ->
        Logs.app
          (fun m -> m "%a lint %a %a: %d errors."
              Text.Pp.status `Fail
              Text.Pp.path dir
              (Fmt.styled_unit `Red "failure") ()
              n);
        1
  in
  Sos.with_dir ~dry_run dir lint pkg
