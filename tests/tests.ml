let () =
  Alcotest.run "dune-release" [
    Test_github.suite;
    Test_pkg.suite;
    Test_remote_repo.suite;
    Test_tags.suite;
  ]
