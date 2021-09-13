module Vcs = Dune_release.Vcs

let test_git_sanitize_tag =
  let make_test name ~input ~expected =
    let expected = Vcs.Tag.of_string expected in
    let name = "git_sanitize_tag: " ^ name in
    let test_fun () =
      Alcotest.(check Alcotest_ext.tag)
        name expected
        (Vcs.git_sanitize_tag input)
    in
    (name, `Quick, test_fun)
  in
  [
    make_test "empty" ~input:"" ~expected:"";
    make_test "valid" ~input:"3.3.4" ~expected:"3.3.4";
    make_test "tilde" ~input:"3.3.4~4.10preview1"
      ~expected:"3.3.4_TILDE_4.10preview1";
    make_test "slash first" ~input:"/v" ~expected:"_SLASH_v";
    make_test "slash not first" ~input:"v/v" ~expected:"v/v";
    make_test "dot last" ~input:"v." ~expected:"v_DOT_";
    make_test "dot not last" ~input:"v.v" ~expected:"v.v";
  ]

let suite = ("Vcs", test_git_sanitize_tag)
