let test_upgrade =
  let make_test ~url ~opam ~v ~expected =
    let test_name = "upgrade" in
    let url = OpamFile.URL.create (OpamUrl.of_string url) in
    let test_fun () =
      let opam_t = OpamFile.OPAM.read_from_string opam in
      let filename = "opam" in
      let id = "6814f8b26946358c72b926706f210025f36619b0" in
      let actual =
        Dune_release.Opam_file.upgrade ~filename ~url ~id opam_t ~version:v
      in
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
    {|x-commit-hash: "6814f8b26946358c72b926706f210025f36619b0"
opam-version: "2.0"
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
    {|x-commit-hash: "6814f8b26946358c72b926706f210025f36619b0"
opam-version: "2.0"
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

let suite = ("Opam_file", test_upgrade)
