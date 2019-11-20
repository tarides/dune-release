let user_from_remote () =
  let check repo_uri expected =
    let repo = Dune_release.Remote_repo.make repo_uri in
    Alcotest.(check (option string))
      repo_uri
      expected
      (Dune_release.Remote_repo.user repo)
  in
  check "git@github.com:username/repo.git" (Some "username");
  check "git@github.com:user-name/repo.git" (Some "user-name");
  check "git@github.com:user-name-123/repo.git" (Some "user-name-123");
  check "git@github.com:123/repo.git" (Some "123");
  (* Same as above but without the .git part *)
  check "git@github.com:username/repo" (Some "username");
  check "git@github.com:user-name/repo" (Some "user-name");
  check "git@github.com:user-name-123/repo" (Some "user-name-123");
  check "git@github.com:123/repo" (Some "123");
  check "wrong" None;
  check "https://github.com/username/repo.git" (Some "username")

let suite =
  "Remote_repo", [
    "user", `Quick, user_from_remote;
  ]
