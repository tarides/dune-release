let () =
  Alcotest.run "dune-release"
    [ Test_github.suite; Test_pkg.suite; Test_stdext.suite; Test_tags.suite ]
