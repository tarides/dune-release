module Vcs = Dune_release.Vcs

let make_test name ~input ~expected ~prefix ~f =
  let name = Printf.sprintf "%s: %s" prefix name in
  let test_fun () = Alcotest.(check string) name expected (f input) in
  (name, `Quick, test_fun)

let t = Vcs.Tag.of_string

let test_git_escape_tag =
  let make_test name ~input ~expected =
    let name = Printf.sprintf "git_escape_tag: %s" name in
    let test_fun () =
      Alcotest.(check Alcotest_ext.tag) name expected (Vcs.git_escape_tag input)
    in
    (name, `Quick, test_fun)
  in
  [
    make_test "empty" ~input:"" ~expected:(t "");
    make_test "valid" ~input:"3.3.4" ~expected:(t "3.3.4");
    make_test "tilde" ~input:"3.3.4~4.10preview1"
      ~expected:(t "3.3.4_4.10preview1");
  ]

let test_git_unescape_tag =
  let make_test name ~input ~expected =
    let name = Printf.sprintf "git_unescape_tag: %s" name in
    let test_fun () =
      Alcotest.(check string) name expected (Vcs.git_unescape_tag input)
    in
    (name, `Quick, test_fun)
  in
  [
    make_test "empty" ~input:(t "") ~expected:"";
    make_test "valid" ~input:(t "3.3.4") ~expected:"3.3.4";
    make_test "tilde" ~input:(t "3.3.4_4.10preview1")
      ~expected:"3.3.4~4.10preview1";
  ]

let suite = ("Vcs", test_git_escape_tag @ test_git_unescape_tag)
