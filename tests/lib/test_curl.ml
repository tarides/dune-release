let test_create_release =
  let make_test ~test_name ~tag ~version ~msg ~user ~repo ~draft ~expected =
    let test_fun () =
      let actual =
        Dune_release.Curl.create_release ~tag ~version ~msg ~user ~repo ~draft
      in
      Alcotest.check Alcotest_ext.curl test_name expected actual
    in
    (test_name, `Quick, test_fun)
  in
  [
    make_test ~test_name:"simple" ~tag:"1.1.0" ~version:"1.1.0"
      ~msg:"this is a message" ~user:"you" ~repo:"some-repo" ~draft:false
      ~expected:
        {
          url = "https://api.github.com/repos/you/some-repo/releases";
          meth = `POST;
          args =
            [
              Location;
              Silent;
              Show_error;
              Config `Stdin;
              Dump_header `Ignore;
              Data
                (`Data
                  {|{"tag_name":"1.1.0","name":"1.1.0","body":"this is a message","draft":false}|});
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
          meth = `POST;
          args =
            [
              Location;
              Silent;
              Show_error;
              Config `Stdin;
              Dump_header `Ignore;
              Header "Content-Type:application/x-tar";
              Data_binary (`File "foo.tgz");
            ];
        };
  ]

let test_open_pr =
  let make_test ~test_name ~title ~user ~branch ~body ~opam_repo ~draft
      ~expected =
    let test_fun () =
      let actual =
        Dune_release.Curl.open_pr ~title ~user ~branch ~body ~opam_repo ~draft
      in
      Alcotest.check Alcotest_ext.curl test_name expected actual
    in
    (test_name, `Quick, test_fun)
  in
  [
    make_test ~test_name:"simple" ~title:"This is a PR" ~user:"you"
      ~branch:"my-best-pr"
      ~body:"This PR fixes everything.\nThis is the best PR.\n"
      ~opam_repo:("base", "repo") ~draft:false
      ~expected:
        {
          url = "https://api.github.com/repos/base/repo/pulls";
          meth = `POST;
          args =
            [
              Silent;
              Show_error;
              Config `Stdin;
              Dump_header `Ignore;
              Data
                (`Data
                  {|{"title":"This is a PR","base":"master","body":"This PR fixes everything.\nThis is the best PR.\n","head":"you:my-best-pr","draft":false}|});
            ];
        };
  ]

let test_with_auth =
  let auth = Dune_release.Curl_option.{ user = "foo"; token = "bar" } in
  let make_test ~test_name ~curl_t ~expected =
    let test_fun () =
      let actual = Dune_release.Curl.with_auth ~auth curl_t in
      Alcotest.check Alcotest_ext.curl test_name expected actual
    in
    (test_name, `Quick, test_fun)
  in
  [
    make_test ~test_name:"basic"
      ~curl_t:
        {
          url = "https://api.github.com/repos/base/repo/pulls";
          meth = `POST;
          args = [ Config `Stdin; Dump_header `Ignore ];
        }
      ~expected:
        {
          url = "https://api.github.com/repos/base/repo/pulls";
          meth = `POST;
          args = [ User auth; Config `Stdin; Dump_header `Ignore ];
        };
  ]

let test_undraft_release =
  let make_test ~test_name ~user ~repo ~release_id ~expected =
    let test_fun () =
      let actual = Dune_release.Curl.undraft_release ~user ~repo ~release_id in
      Alcotest.check Alcotest_ext.curl test_name expected actual
    in
    (test_name, `Quick, test_fun)
  in
  [
    make_test ~test_name:"basic" ~user:"user" ~repo:"some-repo" ~release_id:42
      ~expected:
        {
          url = "https://api.github.com/repos/user/some-repo/releases/42";
          meth = `PATCH;
          args =
            [
              Location;
              Silent;
              Show_error;
              Config `Stdin;
              Dump_header `Ignore;
              Data (`Data {|{ "draft" : false }|});
            ];
        };
  ]

let test_undraft_pr =
  let make_test ~test_name ~opam_repo ~pr_id ~expected =
    let test_fun () =
      let actual = Dune_release.Curl.undraft_pr ~opam_repo ~pr_id in
      Alcotest.check Alcotest_ext.curl test_name expected actual
    in
    (test_name, `Quick, test_fun)
  in
  [
    make_test ~test_name:"basic" ~opam_repo:("x", "y") ~pr_id:42
      ~expected:
        {
          url = "https://api.github.com/repos/x/y/pulls/42";
          meth = `PATCH;
          args =
            [
              Silent;
              Show_error;
              Config `Stdin;
              Dump_header `Ignore;
              Data (`Data {|{ "draft": false }|});
            ];
        };
  ]

let suite =
  ( "Curl",
    test_create_release @ test_upload_archive @ test_open_pr @ test_with_auth
    @ test_undraft_release @ test_undraft_pr )
