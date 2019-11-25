let user_from_remote () =
  let check repo_uri expected =
    Alcotest.(check (option string))
      repo_uri expected
      (Dune_release.Github.Parse.user_from_remote repo_uri)
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

let archive_upload_url () =
  let check response expected =
    match Dune_release.Github.Parse.archive_upload_url response with
    | Ok actual -> Alcotest.(check string) __LOC__ actual expected
    | Error (`Msg msg) -> Alcotest.fail msg
  in
  check
    ( "{"
    ^ {|"url":"https://api.github.com/repos/NathanReb/dune-release-testing/releases/assets/12789323",|}
    ^ {|"id":12789323,|} ^ {|"node_id":"MDEyOlJlbGVhc2VBc3NldDEyNzg5MzIz",|}
    ^ {|"name":"dummy-v0.0.0.tbz",|} ^ {|"label":"",|}
    ^ {|"uploader":{"login":"NathanReb",|} ^ {|"id":7419360,|}
    ^ {|"node_id":"MDQ6VXNlcjc0MTkzNjA=",|}
    ^ {|"avatar_url":"https://avatars2.githubusercontent.com/u/7419360?v=4",|}
    ^ {|"gravatar_id":"",|}
    ^ {|"url":"https://api.github.com/users/NathanReb",|}
    ^ {|"html_url":"https://github.com/NathanReb",|}
    ^ {|"followers_url":"https://api.github.com/users/NathanReb/followers",|}
    ^ {|"following_url":"https://api.github.com/users/NathanReb/following{/other_user}",|}
    ^ {|"gists_url":"https://api.github.com/users/NathanReb/gists{/gist_id}",|}
    ^ {|"starred_url":"https://api.github.com/users/NathanReb/starred{/owner}{/repo}",|}
    ^ {|"subscriptions_url":"https://api.github.com/users/NathanReb/subscriptions",|}
    ^ {|"organizations_url":"https://api.github.com/users/NathanReb/orgs",|}
    ^ {|"repos_url":"https://api.github.com/users/NathanReb/repos",|}
    ^ {|"events_url":"https://api.github.com/users/NathanReb/events{/privacy}",|}
    ^ {|"received_events_url":"https://api.github.com/users/NathanReb/received_events",|}
    ^ {|"type":"User",|} ^ {|"site_admin":false},|}
    ^ {|"content_type":"application/x-tar",|} ^ {|"state":"uploaded",|}
    ^ {|"size":811,|} ^ {|"download_count":0,|}
    ^ {|"created_at":"2019-05-21T09:27:22Z",|}
    ^ {|"updated_at":"2019-05-21T09:27:22Z",|}
    ^ {|"browser_download_url":"https://github.com/NathanReb/dune-release-testing/releases/download/v0.0.0/dummy-v0.0.0.tbz"|}
    ^ "}" )
    "https://github.com/NathanReb/dune-release-testing/releases/download/v0.0.0/dummy-v0.0.0.tbz"

let suite =
  ( "Github",
    [
      ("Parse.user_from_remote", `Quick, user_from_remote);
      ("Parse.archive_upload_url", `Quick, archive_upload_url);
    ] )
