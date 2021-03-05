let test_to_https =
  let make_test ~input ~expected =
    let name = "Uri.Github.to_https " ^ input in
    let actual = Dune_release.Uri.to_https input in
    let test_fun () = Alcotest.(check string) name expected actual in
    (name, `Quick, test_fun)
  in
  [
    make_test ~input:"git@github.com:user/repo.git"
      ~expected:"https://github.com/user/repo";
    make_test ~input:"git+ssh://git@github.com/user/repo"
      ~expected:"https://github.com/user/repo";
    make_test ~input:"git+https://gitlab.com/user/repo"
      ~expected:"https://gitlab";
    make_test ~input:"my_homepage.com" ~expected:"my_homepage";
  ]

let test_to_github_standard =
  let make_test ~input ~expected =
    let name = "Uri.Github.to_github_standard " ^ input in
    let actual = Dune_release.Uri.Github.to_github_standard input in
    let test_fun () =
      Alcotest.(check (Alcotest_ext.result_msg string)) name expected actual
    in
    (name, `Quick, test_fun)
  in
  [
    make_test ~input:"https://user.github.io/repo"
      ~expected:(Ok "https://github.com/user/repo");
    make_test ~input:"https://user.github.io"
      ~expected:(Ok "https://github.com/user/");
    make_test ~input:"https://user.github.io/"
      ~expected:(Ok "https://github.com/user/");
    make_test ~input:"https://user.github.io/some/path"
      ~expected:(Ok "https://github.com/user/some/path");
    make_test ~input:"https://github.com/user/repo"
      ~expected:(Ok "https://github.com/user/repo");
  ]

let test_get_user_and_repo =
  let make_test ~input ~expected =
    let name = "Uri.Github.get_user_and_repo " ^ input in
    let actual = Dune_release.Uri.Github.get_user_and_repo input in
    let test_fun () =
      Alcotest.(check (Alcotest_ext.result_msg (pair string string)))
        name expected actual
    in
    (name, `Quick, test_fun)
  in
  [
    make_test ~input:"https://github.com/user/repo"
      ~expected:(Ok ("user", "repo"));
    make_test ~input:"file://some/path"
      ~expected:
        (Error
           (Bos_setup.R.msgf
              "The following uri is expected to be a web address: \
               \"file://some/path\""));
    make_test ~input:"https://github.com/user/repo/foo"
      ~expected:(Ok ("user", "repo"));
    make_test ~input:"https://github.com/user/repo.fa"
      ~expected:(Ok ("user", "repo"));
    make_test ~input:"https://github.com/user/repo.fa/foo"
      ~expected:(Ok ("user", "repo"));
  ]

let test_split_doc_uri =
  let make_test ~input ~expected =
    let name = "Uri.Github.split_doc_uri " ^ input in
    let actual = Dune_release.Uri.Github.split_doc_uri input in
    let test_fun () =
      Alcotest.(
        check (Alcotest_ext.result_msg (triple string string Alcotest_ext.path)))
        name expected actual
    in
    (name, `Quick, test_fun)
  in
  [
    make_test ~input:"https://user.github.io/repo"
      ~expected:(Ok ("user", "repo", Fpath.v "."));
    make_test ~input:"https://user.github.io/repo/"
      ~expected:(Ok ("user", "repo", Fpath.v "."));
    make_test ~input:"https://user.github.io/repo/path"
      ~expected:(Ok ("user", "repo", Fpath.v "path"));
    make_test ~input:"https://user.github.io/repo/path/"
      ~expected:(Ok ("user", "repo", Fpath.v "path"));
    make_test ~input:"https://user.github.io/repo/long/path/"
      ~expected:(Ok ("user", "repo", Fpath.v "long/path"));
  ]

let suite =
  ( "Uri",
    test_to_https @ test_to_github_standard @ test_get_user_and_repo
    @ test_split_doc_uri )
