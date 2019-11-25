let test_version_of_string =
  let make_test ~input ~expected =
    let name = "Version.of_string " ^ input in
    let test_fun () =
      Alcotest.(check Alcotest_ext.(result_msg opam_version))
        name expected
        (Dune_release.Opam.Version.of_string input)
    in
    (name, `Quick, test_fun)
  in
  let make_failing_test ~input =
    make_test ~input
      ~expected:(Bos_setup.R.error_msgf "unsupported opam version: %S" input)
  in
  [
    make_failing_test ~input:"1.0";
    make_failing_test ~input:"1.0.0";
    make_failing_test ~input:"1.2.0";
    make_test ~input:"1.2.2" ~expected:(Ok V1_2_2);
    make_failing_test ~input:"1.2.2.3";
    make_failing_test ~input:"2";
    make_test ~input:"2.0" ~expected:(Ok V2);
    make_test ~input:"2.0.0" ~expected:(Ok V2);
    make_test ~input:"2.0.1" ~expected:(Ok V2);
  ]

let suite = ("Opam", test_version_of_string)
