(lang dune 2.7)
(name dune-release)

(cram enable)

(generate_opam_files true)

(source (github tarides/dune-release))
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
  (curly (>= 0.3.0))
  (fmt (>= 0.8.7))
  (fpath (>= 0.7.3))
  (bos (>= 0.1.3))
  (cmdliner (>= 1.1.0))
  (re (>= 1.7.2))
  astring
  (opam-file-format (>= 2.1.2))
  (opam-format (>= 2.1.0))
  (opam-state (>= 2.1.0))
  (opam-core (>= 2.1.0))
  (rresult (>= 0.6.0))
  logs
  odoc
  (alcotest :with-test)
  (yojson (>= 1.6)))
 (conflicts
   (result (< 1.5))
   (dune (= 2.7.0))))
