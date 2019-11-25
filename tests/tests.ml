let () =
  Alcotest.run "dune-release"
    [
      Test_github.suite;
      Test_opam.suite;
      Test_pkg.suite;
      Test_stdext.suite;
      Test_tags.suite;
      Test_vcs.suite;
    ]
