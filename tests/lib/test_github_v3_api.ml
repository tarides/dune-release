let test_archive_upload_url =
  let make_test json expected =
    let test_name = "archive_upload_url" in
    let test_fun () =
      let json = Yojson.Basic.from_string json in
      let actual =
        Dune_release.Github_v3_api.Upload_response.browser_download_url json
      in
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
      let actual =
        Dune_release.Github_v3_api.Release_response.release_id json
      in
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
      match Dune_release.Github_v3_api.Pull_request_response.html_url json with
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

let suite =
  ("Github_v3_api", test_archive_upload_url @ test_release_id @ test_html_url)
