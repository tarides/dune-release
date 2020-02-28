open Rresult.R

module D = struct
  let user = "user"

  let repo = "repo"

  let path = Some (Fpath.v "path")
end

let test_homepage =
  let check uri expected =
    let actual = Dune_release.Github_uri.Homepage.of_string uri in
    let ty = Alcotest_ext.(result_msg homepage_uri) in
    let test () = Alcotest.check ty uri expected actual in
    let name = "uri homepage: " ^ uri in
    (name, `Quick, test)
  in
  [
    check "" (error_msg " is an invalid github homepage URI");
    check "wrong" (error_msg "wrong is an invalid github homepage URI");
    check "https://user.github.io"
      (error_msg "https://user.github.io is an invalid github homepage URI");
    check "http://user.github.io/repo"
      (Ok D.{ user; repo; scheme = HTTP; path = None });
    check "https://user.github.io/repo"
      (Ok D.{ user; repo; scheme = HTTPS; path = None });
    check "http://user.github.io/repo/path"
      (Ok D.{ user; repo; scheme = HTTP; path });
    check "https://user.github.io/repo/path"
      (Ok D.{ user; repo; scheme = HTTPS; path });
    check "http://github.com/user/repo"
      (Ok D.{ user; repo; scheme = HTTP; path = None });
    check "https://github.com/user/repo"
      (Ok D.{ user; repo; scheme = HTTPS; path = None });
    check "http://github.com/user/repo/path"
      (Ok D.{ user; repo; scheme = HTTP; path });
    check "https://github.com/user/repo/path"
      (Ok D.{ user; repo; scheme = HTTPS; path });
  ]

let test_doc =
  let check uri expected =
    let actual = Dune_release.Github_uri.Doc.of_string uri in
    let ty = Alcotest_ext.(result_msg doc_uri) in
    let test () = Alcotest.check ty uri expected actual in
    let name = "uri doc: " ^ uri in
    (name, `Quick, test)
  in
  [
    check "" (error_msg " is an invalid github documentation URI");
    check "wrong" (error_msg "wrong is an invalid github documentation URI");
    check "http://user.github.io"
      (error_msg "http://user.github.io is an invalid github documentation URI");
    check "https://user.github.io"
      (error_msg
         "https://user.github.io is an invalid github documentation URI");
    check "http://user.github.io/repo"
      (Ok D.{ user; repo; scheme = HTTP; path = None });
    check "https://user.github.io/repo"
      (Ok D.{ user; repo; scheme = HTTPS; path = None });
    check "http://user.github.io/repo/path"
      (Ok D.{ user; repo; scheme = HTTP; path });
    check "https://user.github.io/repo/path"
      (Ok D.{ user; repo; scheme = HTTPS; path });
  ]

let test_distrib =
  let check uri expected =
    let actual = Dune_release.Github_uri.Distrib.of_string uri in
    let ty = Alcotest_ext.(result_msg distrib_uri) in
    let test () = Alcotest.check ty uri expected actual in
    let name = "uri distrib: " ^ uri in
    (name, `Quick, test)
  in
  [
    check "" (error_msg " is an invalid github distribution URI");
    check "wrong" (error_msg "wrong is an invalid github distribution URI");
    check "http://github.com/user/repo"
      (Ok D.{ user; repo; scheme = HTTP; path = None });
    check "https://github.com/user/repo"
      (Ok D.{ user; repo; scheme = HTTPS; path = None });
    check "http://github.com/user/repo/path"
      (Ok D.{ user; repo; scheme = HTTP; path });
    check "https://github.com/user/repo/path"
      (Ok D.{ user; repo; scheme = HTTPS; path });
  ]

let test_repo =
  let check uri expected =
    let actual = Dune_release.Github_uri.Repo.of_string uri in
    let ty = Alcotest_ext.(result_msg repo_uri) in
    let test () = Alcotest.check ty uri expected actual in
    let name = "uri repo: " ^ uri in
    (name, `Quick, test)
  in
  let open Dune_release.Github_uri.Repo_scheme in
  [
    check "" (error_msg " is an invalid github repository URI");
    check "wrong" (error_msg "wrong is an invalid github repository URI");
    check "git@github.com:user/repo.git"
      (Ok D.{ user; repo; scheme = GIT; git_ext = true });
    check "git@github.com:user-name/repo.git"
      (Ok D.{ user = "user-name"; repo; scheme = GIT; git_ext = true });
    check "git@github.com:user-name-123/repo.git"
      (Ok D.{ user = "user-name-123"; repo; scheme = GIT; git_ext = true });
    check "git@github.com:123/repo.git"
      (Ok D.{ user = "123"; repo; scheme = GIT; git_ext = true });
    check "https://github.com/username/repo.git"
      (Ok D.{ user = "username"; repo; scheme = HTTPS; git_ext = true });
    check "git@github.com:user/repo"
      (Ok D.{ user; repo; scheme = GIT; git_ext = false });
    check "git@github.com:user-name/repo"
      (Ok D.{ user = "user-name"; repo; scheme = GIT; git_ext = false });
    check "git@github.com:user-name-123/repo"
      (Ok D.{ user = "user-name-123"; repo; scheme = GIT; git_ext = false });
    check "git@github.com:123/repo"
      (Ok D.{ user = "123"; repo; scheme = GIT; git_ext = false });
    check "https://github.com/user/repo"
      (Ok D.{ user; repo; scheme = HTTPS; git_ext = false });
  ]

let suite = ("Github_uri", test_homepage @ test_doc @ test_distrib @ test_repo)
