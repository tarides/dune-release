let () =
  Alcotest.run
    "dune-release"
    [ Test_github.test_set
    ]
