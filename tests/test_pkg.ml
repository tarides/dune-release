let test_version_line_re =
  let make_test ~input ~expected =
    let test_name =
      if expected then input ^ "is a valid version field line"
      else input ^ "is not a valid version field line"
    in
    let test_fun () =
      let re = Re.compile Dune_release.Pkg.version_line_re in
      let actual = Re.execp re input in
      Alcotest.(check bool) test_name expected actual
    in
    (test_name, `Quick, test_fun)
  in
  [
    make_test ~input:"" ~expected:false;
    make_test ~input:{|version:""|} ~expected:false;
    make_test ~input:{|version:"1"|} ~expected:true;
    make_test ~input:{|version:     "1"    |} ~expected:true;
    make_test ~input:{|version:"1.jfpojef.adp921709"|} ~expected:true;
  ]

let test_prepare_opam_for_distrib =
  let make_test ~name ~version ~content ~expected () =
    let test_name = "prepare_opam_for_distrib: " ^ name in
    let test_fun () =
      let actual =
        Dune_release.Pkg.prepare_opam_for_distrib ~version ~content
      in
      Alcotest.(check (list string)) test_name expected actual
    in
    (test_name, `Quick, test_fun)
  in
  [
    make_test ~name:"empty" ~content:[] ~version:"1"
      ~expected:[ {|version: "1"|} ] ();
    make_test ~name:"replace version" ~content:[ {|version: "1"|} ] ~version:"2"
      ~expected:[ {|version: "2"|} ] ();
    make_test ~name:"only replace version field"
      ~content:
        [
          {|version: "1"|};
          {|description: """|};
          {|version: "1" blablabla|};
          {|"""|};
        ]
      ~version:"2"
      ~expected:
        [
          {|version: "2"|};
          {|description: """|};
          {|version: "1" blablabla|};
          {|"""|};
        ]
      ();
  ]

let test_upgrade_opam_file =
  let make_test ~url ~opam ~v ~expected =
    let test_name = "upgrade_opam_file" in
    let url = OpamFile.URL.create (OpamUrl.of_string url) in
    let test_fun () =
      let opam_t = OpamFile.OPAM.read_from_string opam in
      let actual = Dune_release.Pkg.upgrade_opam_file ~url ~opam_t v in
      let actual = OpamFile.OPAM.write_to_string actual in
      Alcotest.(check string) test_name expected actual
    in
    (test_name, `Quick, test_fun)
  in
  let url = "https://github.com/foo/foo/foo/foo/bar" in
  let opam =
    {|
opam-version: "2.0"
version: "0.5"
maintainer: "Foo"
authors: ["Foo" "Bar"]
homepage: "https://github.com/foo/bar"
url: "https://github.com/foo/bar"
license: "ISC"
name: "Foo"
dev-repo: "git+https://github.com/foo/bar.git"
depends: [ "foo" "bar" ]
description: "This package is nice"
|}
  in
  let expected_v1 =
    {|opam-version: "2.0"
synopsis: "This package is great"
maintainer: "Foo"
authors: ["Foo" "Bar"]
license: "ISC"
homepage: "https://github.com/foo/bar"
depends: ["ocaml" "foo" "bar"]
dev-repo: "git+https://github.com/foo/bar.git"
url {
  src: "https://github.com/foo/foo/foo/foo/bar"
}|}
  in
  let expected_v2 =
    {|opam-version: "2.0"
synopsis: ""
description: "This package is nice"
maintainer: "Foo"
authors: ["Foo" "Bar"]
license: "ISC"
homepage: "https://github.com/foo/bar"
depends: ["foo" "bar"]
dev-repo: "git+https://github.com/foo/bar.git"
url {
  src: "https://github.com/foo/foo/foo/foo/bar"
}|}
  in
  let descr = OpamFile.Descr.create "This package is great" in
  [
    make_test ~url ~opam ~v:(`V1 descr) ~expected:expected_v1;
    make_test ~url ~opam ~v:`V2 ~expected:expected_v2;
  ]

let suite =
  ( "Pkg",
    test_version_line_re @ test_prepare_opam_for_distrib
    @ test_upgrade_opam_file )
