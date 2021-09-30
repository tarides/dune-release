(lang dune 2.7)
(name dune-release)

(using mdx 0.1)

(generate_opam_files true)

(source (github ocamllabs/dune-release))
(license ISC)
(authors
  "Daniel Bünzli"
  "Thomas Gazagnaire"
  "Nathan Rebours"
  "Guillaume Petiot"
  "Sonja Heinze")
(maintainers "Nathan Rebours <nathan.p.rebours@gmail.com>")

(package
 (name dune-release)
 (synopsis "Release dune packages in opam")
 (description
"`dune-release` is a tool to streamline the release of Dune packages in
[opam](https://opam.ocaml.org). It supports projects built
with [Dune](https://github.com/ocaml/dune) and hosted on
[GitHub](https://github.com).")
 (depends
  (ocaml (>= 4.06.0))
  curly
  fmt
  bos
  cmdliner
  re
  astring
  (opam-format (>= 2.1.0~beta))
  (opam-state (>= 2.1.0~beta))
  (opam-core (>= 2.1.0~beta))
  rresult
  logs
  odoc
  (alcotest :with-test)
  (mdx (and :with-test (>= 1.6.0)))
  yojson))
