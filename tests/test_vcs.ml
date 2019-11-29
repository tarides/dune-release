let cmd_error () =
  let check ~name ~cmd ~status ~expected =
    let name = "cmd_error: " ^ name in
    match Dune_release.Vcs.cmd_error cmd status with
    | Ok _ -> Alcotest.fail name (* Vcs.cmd_error always returns an Error *)
    | Error (`Msg e) -> Alcotest.(check string) name expected e
  in
  let cmd =
    Bos_setup.Cmd.(
      v "git" % "--git-dir" % ".git" % "--work-tree" % "." % "diff-index"
      % "--quiet" % "HEAD")
  in
  check ~name:"cmd exited" ~cmd ~status:(`Exited 2)
    ~expected:
      "The following command exited with code 2:\n\
       git --git-dir .git --work-tree . diff-index --quiet HEAD";
  check ~name:"cmd signaled" ~cmd ~status:(`Signaled 3)
    ~expected:
      "The following command exited with signal 3:\n\
       git --git-dir .git --work-tree . diff-index --quiet HEAD"

let suite = ("Vcs", [ ("cmd_error", `Quick, cmd_error) ])
