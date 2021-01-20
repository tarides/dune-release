open Dune_release.Github_v3_api

let test_create_release =
  let make_test ~test_name ~version ~msg ~user ~repo ~draft ~expected =
    let test_fun () =
      let actual = Release.Request.create ~version ~msg ~user ~repo ~draft in
      Alcotest.check Alcotest_ext.curl test_name expected actual
    in
    (test_name, `Quick, test_fun)
  in
  [
    make_test ~test_name:"simple" ~version:"1.1.0" ~msg:"this is a message"
      ~user:"you" ~repo:"some-repo" ~draft:false
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
                  {|{ "tag_name" : "1.1.0", "name" : "1.1.0", "body" : "this is a message", "draft" : false }|});
            ];
        };
  ]

let test_upload_archive =
  let make_test ~test_name ~archive ~user ~repo ~release_id ~expected =
    let test_fun () =
      let archive = Fpath.v archive in
      let actual = Archive.Request.upload ~archive ~user ~repo ~release_id in
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
        Pull_request.Request.open_ ~title ~user ~branch ~body ~opam_repo ~draft
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
                  {|{"title": "This is a PR","base": "master", "body": "This PR fixes everything.\nThis is the best PR.\n", "head": "you:my-best-pr", "draft": false}|});
            ];
        };
  ]

let test_with_auth =
  let auth = Dune_release.Curl_option.{ user = "foo"; token = "bar" } in
  let make_test ~test_name ~curl_t ~expected =
    let test_fun () =
      let actual = with_auth ~auth curl_t in
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
      let actual = Release.Request.undraft ~user ~repo ~release_id in
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
      let actual = Pull_request.Request.undraft ~opam_repo ~pr_id in
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

let test_archive_upload_url =
  let make_test json expected =
    let test_name = "archive_upload_url" in
    let test_fun () =
      let json = Yojson.Basic.from_string json in
      let actual = Archive.Response.browser_download_url json in
      Alcotest.(check (Alcotest_ext.result_msg string)) __LOC__ expected actual
    in
    (test_name, `Quick, test_fun)
  in
  [
    make_test Upload_response.gh_v3_api_DR_example
      (Ok
         "https://github.com/NathanReb/dune-release-testing/releases/download/v0.0.0/dummy-v0.0.0.tbz");
    make_test Upload_response.gh_v3_api_example
      (Ok
         "https://github.com/octocat/Hello-World/releases/download/v1.0.0/example.zip");
  ]

let test_release_id =
  let make_test json expected =
    let json = Yojson.Basic.from_string json in
    let test_name = "release_id" in
    let test_fun () =
      let actual = Release.Response.release_id json in
      Alcotest.(check (Alcotest_ext.result_msg int)) __LOC__ expected actual
    in
    (test_name, `Quick, test_fun)
  in
  [ make_test Create_release_response.gh_v3_api_example (Ok 1) ]

let test_html_url =
  let make_test name json expected =
    let test_name = "html_url: " ^ name in
    let test_fun () =
      let json = Yojson.Basic.from_string json in
      match Pull_request.Response.html_url json with
      | Ok (`Url actual) -> Alcotest.(check string) __LOC__ expected actual
      | Ok `Already_exists ->
          Alcotest.(check string) __LOC__ expected "ALREADY_EXISTS"
      | Error (`Msg msg) -> Alcotest.(check string) __LOC__ expected msg
    in
    (test_name, `Quick, test_fun)
  in
  [
    make_test "passing" Pull_request_response.gh_v3_api_example
      "https://github.com/octocat/Hello-World/pull/1347";
    make_test "handled failure" Pull_request_response.gh_v3_api_handled_failure
      {|ALREADY_EXISTS|};
    make_test "unhandled failure"
      Pull_request_response.gh_v3_api_unhandled_failure
      {|Github API error:
  Could not retrieve pull request URL from response
  Github API returned: "Validation Failed"
  See the documentation "https://docs.github.com/rest/reference/pulls#create-a-pull-request" that might help you resolve this error.
  - Error message: "This is an unhandled failure."
  - Code: "custom"|};
  ]

let test_number =
  let make_test json expected =
    let test_name = "number" in
    let test_fun () =
      let json = Yojson.Basic.from_string json in
      let actual = Pull_request.Response.number json in
      Alcotest.(check (Alcotest_ext.result_msg int)) __LOC__ expected actual
    in
    (test_name, `Quick, test_fun)
  in
  [ make_test Pull_request_response.gh_v3_api_example (Ok 1347) ]

let suite =
  ( "Github_v3_api",
    test_create_release @ test_upload_archive @ test_open_pr @ test_with_auth
    @ test_undraft_release @ test_undraft_pr @ test_archive_upload_url
    @ test_release_id @ test_html_url @ test_number )
