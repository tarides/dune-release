let test_git_sanitize_tag =
  let make_test name ~input ~expected =
    let name = "git_sanitize_tag: " ^ name in
    let test_fun () =
      Alcotest.(check string)
        name expected
        (Dune_release.Vcs.git_sanitize_tag input)
    in
    (name, `Quick, test_fun)
  in
  [
    make_test "empty" ~input:"" ~expected:"";
    make_test "valid" ~input:"3.3.4" ~expected:"3.3.4";
    make_test "tilde" ~input:"3.3.4~4.10preview1"
      ~expected:"3.3.4_TILDE_4.10preview1";
  ]

let suite = ("Vcs", test_git_sanitize_tag)
