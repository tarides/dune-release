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

let suite = ("Github", test_user_from_remote)
