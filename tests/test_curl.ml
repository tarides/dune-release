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

let test_upload_archive =
  let make_test ~test_name ~archive ~user ~repo ~release_id ~expected =
    let test_fun () =
      let archive = Fpath.v archive in
      let actual =
        Dune_release.Curl.upload_archive ~archive ~user ~repo ~release_id
      in
      Alcotest.(check (list string)) test_name expected actual
    in
    (test_name, `Quick, test_fun)
  in
  [
    make_test ~test_name:"simple" ~archive:"foo.tgz" ~user:"you"
      ~repo:"some-repo" ~release_id:27
      ~expected:
        [
          "-H";
          "Content-Type:application/x-tar";
          "--data-binary";
          "@foo.tgz";
          "https://uploads.github.com/repos/you/some-repo/releases/27/assets?name=foo.tgz";
        ];
  ]

let suite = ("Curl", test_create_release @ test_upload_archive)
