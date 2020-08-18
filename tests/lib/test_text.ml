let test_change_log_last_entry =
  let make_test ~name ~input ~expected =
    let name = "change_log_last_entry " ^ name in
    let test_fun () =
      Alcotest.(check (option (pair string (pair string string))))
        name expected
        (Dune_release.Text.change_log_last_entry input)
    in
    (name, `Quick, test_fun)
  in
  [
    make_test ~name:"empty" ~input:"" ~expected:None;
    make_test ~name:"change list 0"
      ~input:{|
# v0.1
  - change A  
  - change B  
|}
      ~expected:(Some ("v0.1", ("# v0.1", "  - change A\n  - change B")));
    make_test ~name:"change list 1"
      ~input:{|
# v0.1

  - change A
  - change B
|}
      ~expected:(Some ("v0.1", ("# v0.1", "  - change A\n  - change B")));
    make_test ~name:"change list 2"
      ~input:{|
# v0.1


  - change A
  - change B
|}
      ~expected:(Some ("v0.1", ("# v0.1", "\n  - change A\n  - change B")));
    make_test ~name:"many entries"
      ~input:{|
# v0.1

change A

# v0.0.1

change B
|}
      ~expected:(Some ("v0.1", ("# v0.1", "change A")));
  ]

let suite = ("Text", test_change_log_last_entry)
