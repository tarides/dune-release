let cmd_error () =
  let check ~name ~cmd ~err_msg ~status ~expected () =
    let name = "cmd_error: " ^ name in
    match Dune_release.Sos.cmd_error cmd err_msg status with
    | Ok _ -> Alcotest.fail name (* Vcs.cmd_error always returns an Error *)
    | Error (`Msg e) -> Alcotest.(check string) name expected e
  in
  let cmd =
    Bos_setup.Cmd.(
      v "git" % "--git-dir" % ".git" % "--work-tree" % "." % "diff-index"
      % "--quiet" % "HEAD")
  in
  check ~name:"cmd exited" ~cmd ~err_msg:None ~status:(`Exited 2)
    ~expected:
      "The following command exited with code 2:\n\
      \  git --git-dir .git --work-tree . diff-index --quiet HEAD"
    ();
  check ~name:"cmd signaled" ~cmd ~err_msg:None ~status:(`Signaled 3)
    ~expected:
      "The following command exited with signal 3:\n\
      \  git --git-dir .git --work-tree . diff-index --quiet HEAD"
    ();
  check ~name:"cmd exited verbose" ~cmd
    ~err_msg:(Some "fatal: This is all made up\n") ~status:(`Exited 2)
    ~expected:
      "Exit code 2 from command\n\
      \  `git --git-dir .git --work-tree . diff-index --quiet HEAD`:\n\
       fatal: This is all made up\n"
    ();
  check ~name:"cmd signaled verbose" ~cmd
    ~err_msg:(Some "fatal: This is all made up\n") ~status:(`Signaled 3)
    ~expected:
      "Signal 3 from command \n\
      \  `git --git-dir .git --work-tree . diff-index --quiet HEAD`:\n\
       fatal: This is all made up\n"
    ()

let suite = ("Sos", [ ("cmd_error", `Quick, cmd_error) ])
