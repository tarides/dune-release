let test_to_https =
  let make_test ~input ~expected =
    let name = "to_https " ^ input in
    let actual = Dune_release.Uri_helpers.to_https input in
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

let suite =
  ( "Uri_helpers", test_to_https )
