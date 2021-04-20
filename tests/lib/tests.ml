let () =
  Alcotest.run "dune-release"
    [
      Test_github.suite;
      Test_github_v3_api.suite;
      Test_github_v4_api.suite;
      Test_opam.suite;
      Test_opam_file.suite;
      Test_pkg.suite;
      Test_stdext.suite;
      Test_tags.suite;
      Test_text.suite;
      Test_sos.suite;
      Test_vcs.suite;
      Test_uri_helpers.suite;
      Test_github_repo.suite;
    ]
