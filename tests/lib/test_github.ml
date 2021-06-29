let test_ssh_uri_from_http =
  let check inp expected =
    let test_name = "Parse.ssh_uri_from_http " ^ inp in
    let result = Dune_release.Github.Parse.ssh_uri_from_http inp in
    let test_fun () = Alcotest.(check (option string)) inp expected result in
    (test_name, `Quick, test_fun)
  in
  [
    (* Use cases *)
    check "https://github.com/ocamllabs/dune-release"
      (Some "git@github.com:ocamllabs/dune-release");
    check "git@github.com:ocamllabs/dune-release"
      (Some "git@github.com:ocamllabs/dune-release");
    (* This function only works for github https urls, returns its input
       otherwise *)
    check "https://not-github.com/dune-release" None;
    check "git@not-github.com:dune-release" None;
    check "git://github.com/user/repo.git" (Some "git@github.com:user/repo.git");
    check "git+https://github.com/user/repo.git" None;
  ]

let suite = ("Github", test_ssh_uri_from_http)
