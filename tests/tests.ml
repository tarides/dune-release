let () =
  Alcotest.run "dune-release" [
    Test_github.suite;
    Test_tags.suite;
  ]
