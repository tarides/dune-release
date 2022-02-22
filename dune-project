(lang dune 2.7)
(name dune-release)

(cram enable)

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
  (ocaml (>= 4.08.0))
  curly
  (fmt (>= 0.8.7))
  (fpath (>= 0.7.3))
  bos
  (cmdliner (>= 1.1.0))
  (re (>= 1.7.2))
  astring
  (opam-file-format (>= 2.1.2))
  (opam-format (>= 2.1.0))
  (opam-state (>= 2.1.0))
  (opam-core (>= 2.1.0))
  rresult
  logs
  odoc
  (alcotest :with-test)
  (yojson (>= 1.6))))

(package
 (name dune_release.bin)
 (synopsis "Release dune packages in opam")
 (description
"`dune-release` is a tool to streamline the release of Dune packages in
[opam](https://opam.ocaml.org). It supports projects built
with [Dune](https://github.com/ocaml/dune) and hosted on
[GitHub](https://github.com).")
 (depends
  (ocaml (>= 4.06.0))
  curly
  (fmt (>= 0.8.7))
  (fpath (>= 0.7.3))
  bos
  cmdliner
  (re (>= 1.7.2))
  astring
  (opam-file-format (>= 2.1.2))
  (opam-format (>= 2.1.0))
  (opam-state (>= 2.1.0))
  (opam-core (>= 2.1.0))
  rresult
  logs
  odoc
  (alcotest :with-test)
  (yojson (>= 1.6))))

