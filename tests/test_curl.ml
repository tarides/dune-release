let test_create_release =
  let make_test ~test_name ~version ~msg ~user ~repo ~expected =
    let test_fun () =
      let actual = Dune_release.Curl.create_release ~version ~msg ~user ~repo in
      Alcotest.check Alcotest_ext.curl test_name expected actual
    in
    (test_name, `Quick, test_fun)
  in
  [
    make_test ~test_name:"simple" ~version:"1.1.0" ~msg:"this is a message"
      ~user:"you" ~repo:"some-repo"
      ~expected:
        {
          url = "https://api.github.com/repos/you/some-repo/releases";
          args =
            [
              "-L";
              "-s";
              "-S";
              "-K";
              "-";
              "-D";
              "-";
              "--data";
              {|{ "tag_name" : "1.1.0", "body" : "this is a message" }|};
            ];
        };
  ]

let test_upload_archive =
  let make_test ~test_name ~archive ~user ~repo ~release_id ~expected =
    let test_fun () =
      let archive = Fpath.v archive in
      let actual =
        Dune_release.Curl.upload_archive ~archive ~user ~repo ~release_id
      in
      Alcotest.check Alcotest_ext.curl test_name expected actual
    in
    (test_name, `Quick, test_fun)
  in
  [
    make_test ~test_name:"simple" ~archive:"foo.tgz" ~user:"you"
      ~repo:"some-repo" ~release_id:27
      ~expected:
        {
          url =
            "https://uploads.github.com/repos/you/some-repo/releases/27/assets?name=foo.tgz";
          args =
            [
              "-L";
              "-s";
              "-S";
              "-K";
              "-";
              "-H";
              "Content-Type:application/x-tar";
              "--data-binary";
              "@foo.tgz";
            ];
        };
  ]

let test_open_pr =
  let make_test ~test_name ~title ~user ~branch ~body ~opam_repo ~expected =
    let test_fun () =
      let actual =
        Dune_release.Curl.open_pr ~title ~user ~branch ~body ~opam_repo
      in
      Alcotest.check Alcotest_ext.curl test_name expected actual
    in
    (test_name, `Quick, test_fun)
  in
  [
    make_test ~test_name:"simple" ~title:"This is a PR" ~user:"you"
      ~branch:"my-best-pr"
      ~body:"This PR fixes everything.\nThis is the best PR.\n"
      ~opam_repo:("base", "repo")
      ~expected:
        {
          url = "https://api.github.com/repos/base/repo/pulls";
          args =
            [
              "-s";
              "-S";
              "-K";
              "-";
              "-D";
              "-";
              "--data";
              {|{"title": "This is a PR","base": "master", "body": "This PR fixes everything.\nThis is the best PR.\n", "head": "you:my-best-pr"}|};
            ];
        };
  ]

let suite = ("Curl", test_create_release @ test_upload_archive @ test_open_pr)
