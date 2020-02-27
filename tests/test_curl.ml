let test_create_release =
  let make_test ~test_name ~version ~msg ~user ~repo ~expected =
    let test_fun () =
      let actual = Dune_release.Curl.create_release ~version ~msg ~user ~repo in
      Alcotest.(check (list string)) test_name expected actual
    in
    (test_name, `Quick, test_fun)
  in
  [
    make_test ~test_name:"simple" ~version:"1.1.0" ~msg:"this is a message"
      ~user:"you" ~repo:"some-repo"
      ~expected:
        [
          "-D";
          "-";
          "--data";
          {|{ "tag_name" : "1.1.0", "body" : "this is a message" }|};
          "https://api.github.com/repos/you/some-repo/releases";
        ];
  ]

let suite = ("Curl", test_create_release)
