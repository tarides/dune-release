let test_user_from_remote =
  let make_test repo_uri expected =
    let test_name = "Parse.user_from_remote " ^ repo_uri in
    let test_fun () =
      Alcotest.(check (option string))
        repo_uri expected
        (Dune_release.Github.Parse.user_from_remote repo_uri)
    in
    (test_name, `Quick, test_fun)
  in
  [
    make_test "git@github.com:username/repo.git" (Some "username");
    make_test "git@github.com:user-name/repo.git" (Some "user-name");
    make_test "git@github.com:user-name-123/repo.git" (Some "user-name-123");
    make_test "git@github.com:123/repo.git" (Some "123");
    (* Same as above but without the .git part *)
    make_test "git@github.com:username/repo" (Some "username");
    make_test "git@github.com:user-name/repo" (Some "user-name");
    make_test "git@github.com:user-name-123/repo" (Some "user-name-123");
    make_test "git@github.com:123/repo" (Some "123");
    make_test "wrong" None;
    make_test "https://github.com/username/repo.git" (Some "username");
  ]

let test_ssh_uri_from_http =
  let check inp expected =
    let test_name = "Parse.ssh_uri_from_http " ^ inp in
    let result = Dune_release.Github.Parse.ssh_uri_from_http inp in
    let test_fun () = Alcotest.(check string) inp expected result in
    (test_name, `Quick, test_fun)
  in
  [
    (* Use cases *)
    check "https://github.com/ocamllabs/dune-release"
      "git@github.com:ocamllabs/dune-release";
    check "git@github.com:ocamllabs/dune-release"
      "git@github.com:ocamllabs/dune-release";
    (* This function only works for github https urls, returns its input
       otherwise *)
    check "https://not-github.com/dune-release"
      "https://not-github.com/dune-release";
    check "git@not-github.com:dune-release" "git@not-github.com:dune-release";
  ]

let suite = ("Github", test_user_from_remote @ test_ssh_uri_from_http)
