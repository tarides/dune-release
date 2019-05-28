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
        Logs.app (fun m -> m "%a @[lint@ %s %a.@]" Text.Pp.status `Ok file_kind Text.Pp.path file);
        errs
    | `Fail msgs ->
        Logs.app
          (fun m -> m "%a @[<v>@[lint@ %s %a:@]@,@[%a messages:@]@,%a@]"
              Text.Pp.status `Fail file_kind Text.Pp.path file Cmd.pp cmd Fmt.lines msgs);
        errs + 1
  end
  |> Logs.on_error_msg ~use:(fun () -> errs + 1)

let lint_opams ~dry_run pkg =
  let tool_version = Lazy.force Opam.version in
  let lint opam_version =
    let args = match opam_version, Lazy.force Opam.version with
    | Some ["1.2"], `v2 -> Cmd.v "--warn=-21-32-48"
    | _ -> Cmd.empty
    in
    Pkg.opam pkg >>= fun opam ->
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
      Pkg.doc_user_repo_and_path pkg >>= fun _ ->
      Pkg.distrib_user_and_repo pkg >>| fun _ ->
      d
    )
  in
  Logs.on_error_msg ~use:(fun () -> 1) (
    (* remove opam.1.2-related warnings *)
    Pkg.opam_field pkg "opam-version" >>= fun opam_version ->
    match opam_version, tool_version with
    | Some ["2.0"], `v1_2_2 ->
        Logs.app (fun m ->
            m "Skipping opam lint as `opam-version` field is \"2.0\" \
               while `opam --version` is 1.2.2");
        Ok 0
    | Some ["2.0"], _ ->
        (* check that the descr and synopsis fields are not empty *)
        Pkg.opam_field pkg "description" >>= fun descr ->
        Pkg.opam_field pkg "synopsis" >>= fun synopsis ->
        Pkg.opam pkg >>= fun opam ->
        if descr = None then
          R.error_msgf "%a does not have a 'description' field." Fpath.pp opam
        else if synopsis = None || synopsis = Some [""] then
          R.error_msgf "%a does not have a 'synopsis' field" Fpath.pp opam
        else
        lint opam_version
    | _ -> lint opam_version)

let ts =
  [`Std_files, lint_std_files;
   `Opam, lint_opams ]

let all = List.map fst ts

let lint_pkg ~dry_run ~dir pkg todo =
  let lint pkg =
    let do_lint acc (t, f) = acc + if List.mem t todo then f ~dry_run pkg else 0 in
    match List.fold_left do_lint 0 ts with
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
