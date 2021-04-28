let t =
  let open Dune_release.Github_repo in
  Alcotest.testable pp equal

let test_from_uri =
  let make_test ~input ~expected =
    let name = Printf.sprintf "from_uri %S" input in
    let test_fun () =
      let actual = Dune_release.Github_repo.from_uri input in
      Alcotest.(check (option t)) name expected actual
    in
    (name, `Quick, test_fun)
  in
  [
    make_test ~input:"https://github.com/owner/repo"
      ~expected:(Some { owner = "owner"; repo = "repo" });
    make_test ~input:"https://github.com/owner/repo.git"
      ~expected:(Some { owner = "owner"; repo = "repo" });
    make_test ~input:"git+https://github.com/owner/repo.git"
      ~expected:(Some { owner = "owner"; repo = "repo" });
    make_test ~input:"git@github.com:owner/repo.git"
      ~expected:(Some { owner = "owner"; repo = "repo" });
    make_test ~input:"ssh://git@github.com:owner/repo.git"
      ~expected:(Some { owner = "owner"; repo = "repo" });
    make_test ~input:"git+ssh://git@github.com:owner/repo.git"
      ~expected:(Some { owner = "owner"; repo = "repo" });
    make_test ~input:"https://owner.github.io/repo"
      ~expected:(Some { owner = "owner"; repo = "repo" });
    make_test ~input:"https://owner.github.io/repo/path"
      ~expected:(Some { owner = "owner"; repo = "repo" });
    make_test ~input:"https://gitlab.com/owner/repo" ~expected:None;
  ]

let test_https_uri =
  let make_test ~name ~input ~expected =
    let name = Printf.sprintf "https_uri: %S" name in
    let test_fun () =
      let actual = Dune_release.Github_repo.https_uri input in
      Alcotest.(check string) name expected actual
    in
    (name, `Quick, test_fun)
  in
  [
    make_test ~name:"Simple"
      ~input:{ owner = "owner"; repo = "repo" }
      ~expected:"https://github.com/owner/repo";
  ]

let test_ssh_uri =
  let make_test ~name ~input ~expected =
    let name = Printf.sprintf "ssh_uri: %S" name in
    let test_fun () =
      let actual = Dune_release.Github_repo.ssh_uri input in
      Alcotest.(check string) name expected actual
    in
    (name, `Quick, test_fun)
  in
  [
    make_test ~name:"Simple"
      ~input:{ owner = "owner"; repo = "repo" }
      ~expected:"git@github.com:owner/repo.git";
  ]

let test_from_gh_pages =
  let make_test ~input ~expected =
    let name = "from_gh_pages: " ^ input in
    let test_fun () =
      let actual = Dune_release.Github_repo.from_gh_pages input in
      Alcotest.(check (option (pair t Alcotest_ext.path))) name expected actual
    in
    (name, `Quick, test_fun)
  in
  [
    make_test ~input:"https://user.github.io/repo"
      ~expected:(Some ({ owner = "user"; repo = "repo" }, Fpath.v "."));
    make_test ~input:"https://user.github.io/repo/"
      ~expected:(Some ({ owner = "user"; repo = "repo" }, Fpath.v "."));
    make_test ~input:"https://user.github.io/repo/path"
      ~expected:(Some ({ owner = "user"; repo = "repo" }, Fpath.v "path"));
    make_test ~input:"https://user.github.io/repo/path/"
      ~expected:(Some ({ owner = "user"; repo = "repo" }, Fpath.v "path"));
    make_test ~input:"https://user.github.io/repo/long/path/"
      ~expected:
        (Some ({ owner = "user"; repo = "repo" }, Fpath.(v "long" / "path")));
  ]

let suite =
  ( "Github_repo",
    test_from_uri @ test_https_uri @ test_ssh_uri @ test_from_gh_pages )
