let uri =
  let open Dune_release.Uri_helpers in
  Alcotest.testable pp_uri equal_uri

let test_parse =
  let make_test ~input ~expected =
    let name = Printf.sprintf "parse: %s" input in
    let test_fun () =
      let actual = Dune_release.Uri_helpers.parse input in
      Alcotest.(check (option uri)) name expected actual
    in
    (name, `Quick, test_fun)
  in
  [
    make_test ~input:"scheme://domain.com/some/path"
      ~expected:
        (Some
           {
             scheme = Some "scheme";
             domain = [ "com"; "domain" ];
             path = [ "some"; "path" ];
           });
    make_test ~input:"noscheme.com/some/path"
      ~expected:
        (Some
           {
             scheme = None;
             domain = [ "com"; "noscheme" ];
             path = [ "some"; "path" ];
           });
    make_test ~input:"nopath.com"
      ~expected:
        (Some { scheme = None; domain = [ "com"; "nopath" ]; path = [] });
    make_test ~input:"git@github.com:some/path"
      ~expected:
        (Some
           {
             scheme = None;
             domain = [ "com"; "git@github" ];
             path = [ "some"; "path" ];
           });
  ]

let suite = ("Uri_helpers", test_parse)
