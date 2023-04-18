let test_ssh_uri_from_http =
  let check inp expected =
    let test_name = "Parse.ssh_uri_from_http " ^ inp in
    let result = Dune_release.Github.Parse.ssh_uri_from_http inp in
    let test_fun () = Alcotest.(check (option string)) inp expected result in
    (test_name, `Quick, test_fun)
  in
  [
    (* Use cases *)
    check "https://github.com/tarides/dune-release"
      (Some "git@github.com:tarides/dune-release");
    check "git@github.com:tarides/dune-release"
      (Some "git@github.com:tarides/dune-release");
    (* This function only works for github https urls, returns its input
       otherwise *)
    check "https://not-github.com/dune-release" None;
    check "git@not-github.com:dune-release" None;
    check "git://github.com/user/repo.git" (Some "git@github.com:user/repo.git");
    check "git+https://github.com/user/repo.git" None;
  ]

let test_pr_title =
  let check test_name ~project_name ~names ~expected =
    let version = Dune_release.Version.of_string "1.2.3" in
    let got = Dune_release.Github.pr_title ~names ~version ~project_name in
    let test_fun () = Alcotest.(check string) __LOC__ expected got in
    (test_name, `Quick, test_fun)
  in
  [
    check "No project name" ~project_name:None ~names:[ "a"; "b"; "c" ]
      ~expected:"[new release] a, b and c (1.2.3)";
    check "With project name" ~project_name:(Some "b") ~names:[ "a"; "b"; "c" ]
      ~expected:"[new release] b (3 packages) (1.2.3)";
    check "1 package with project name" ~project_name:(Some "a") ~names:[ "a" ]
      ~expected:"[new release] a (1.2.3)";
  ]

let suite = ("Github", test_ssh_uri_from_http @ test_pr_title)
