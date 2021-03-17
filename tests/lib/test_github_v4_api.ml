open Dune_release.Github_v4_api

let test_with_auth =
  let token = "token" in
  let make_test ~test_name ~curl_t ~expected =
    let test_fun () =
      let actual = with_auth ~token curl_t in
      Alcotest.check Alcotest_ext.curl test_name expected actual
    in
    (test_name, `Quick, test_fun)
  in
  [
    make_test ~test_name:"basic"
      ~curl_t:
        {
          url = "https://api.github.com/graphql";
          meth = `POST;
          args = [ Config `Stdin; Dump_header `Ignore ];
        }
      ~expected:
        {
          url = "https://api.github.com/graphql";
          meth = `POST;
          args =
            [
              Header (Bos_setup.strf "Authorization: bearer %s" token);
              Config `Stdin;
              Dump_header `Ignore;
            ];
        };
  ]

let test_pr_request_node_id =
  let make_test ~name ~user ~repo ~id ~expected =
    let test_name = "Pull_request.Request.node_id: " ^ name in
    let test_fun () =
      let actual = Pull_request.Request.node_id ~user ~repo ~id in
      Alcotest.check Alcotest_ext.curl test_name expected actual
    in
    (test_name, `Quick, test_fun)
  in
  [
    make_test ~name:"simple" ~user:"you" ~repo:"some-repo" ~id:4
      ~expected:
        {
          url = "https://api.github.com/graphql";
          meth = `POST;
          args =
            [
              Data
                (`Data
                  {|{ "query": "query { repository(owner:\"you\", name:\"some-repo\") { pullRequest(number:4) { id } } }" }|});
            ];
        };
  ]

let test_pr_ready_for_review =
  let make_test ~name ~node_id ~expected =
    let test_name = "Pull_request.Request.ready_for_review: " ^ name in
    let test_fun () =
      let actual = Pull_request.Request.ready_for_review ~node_id in
      Alcotest.check Alcotest_ext.curl test_name expected actual
    in
    (test_name, `Quick, test_fun)
  in
  [
    make_test ~name:"simple" ~node_id:"node_id"
      ~expected:
        {
          url = "https://api.github.com/graphql";
          meth = `POST;
          args =
            [
              Data
                (`Data
                  {|{ "query": "mutation { markPullRequestReadyForReview (input : {clientMutationId:\"dune-release\",pullRequestId:\"node_id\"}) { pullRequest { url } } }" }|});
            ];
        };
  ]

let test_pr_response_node_id =
  let make_test name json expected =
    let test_name = "Pull_request.Response.node_id: " ^ name in
    let test_fun () =
      let json = Yojson.Basic.from_string json in
      match Pull_request.Response.node_id json with
      | Ok id -> Alcotest.(check string) __LOC__ expected id
      | Error (`Msg msg) -> Alcotest.(check string) __LOC__ expected msg
    in
    (test_name, `Quick, test_fun)
  in
  [
    make_test "passing" Pull_request_response.gh_v4_api_node_id_example
      "MDExOlB1bGxSZXF1ZXN0NTUxODAxMTU2";
    make_test "unhandled failure"
      Pull_request_response.gh_v4_api_node_id_unhandled_failure
      "Github API error:\n\
      \  Could not retrieve node_id from pull request\n\
      \  Github API returned: Could not resolve to a Repository with the name \
       'user/foo'.";
  ]

let test_pr_response_url =
  let make_test name json expected =
    let test_name = "Pull_request.Response.url: " ^ name in
    let test_fun () =
      let json = Yojson.Basic.from_string json in
      match Pull_request.Response.url json with
      | Ok id -> Alcotest.(check string) __LOC__ expected id
      | Error (`Msg msg) -> Alcotest.(check string) __LOC__ expected msg
    in
    (test_name, `Quick, test_fun)
  in
  [
    make_test "passing" Pull_request_response.gh_v4_api_url_example
      "https://github.com/user/opam-repository/pull/8";
    make_test "unhandled failure"
      Pull_request_response.gh_v4_api_url_unhandled_failure
      "Github API error:\n\
      \  Could not retrieve url from pull request\n\
      \  Github API returned: Could not resolve to a node with the global id \
       of 'foo'";
  ]

let suite =
  ( "Github_v4_api",
    test_with_auth @ test_pr_request_node_id @ test_pr_response_node_id
    @ test_pr_ready_for_review @ test_pr_response_url )
