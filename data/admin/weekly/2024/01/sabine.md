sabine week 1: 2024/01/01 -- 2024/01/07

# Projects

- Management (#1109)
- General ocaml.org maintenance (Plat187)
- Sunset opam.ocaml.org in favour of ocaml.org package documentation (Plat251)
- New version of the OCaml documentation (Plat194)
- Redesign OCaml.org Learn Area According to User Feedback (Plat278)

# Last Week

- Management (#1109)
  - @sabine (0.5 days)
  - team meeting
  - design check in
  - shakthi check in
  - Sayo 1:1
  - Sayo goodbye meet with the team

- General ocaml.org maintenance (Plat187)
  - @sabine (3.5 days)
  - Work Item 1

  - on Thursday I started streaming at twitch.tv/sabine_ocaml
    - trying to fix https://github.com/ocaml-doc/voodoo/issues/129 on stream
    - we now read the library names from the META files, and only afterwards look up the modules for the libraries using ocamlobjinfo, tested that it works on ptime and hsluv
    - For leostera/riot, __private__ libraries are exposed, we could filter for that, but since riot is a dune package, we should probably instead parse its dune-package file correctly
    - since reading `dune-package` proved to be difficult to support for all dune versions and will cause repeated maintenance needs: removed the code reading dune-package to see if anything breaks when we do so

  - In response to @metame's stream, I make some proposals for improving the "Managing Dependencies with opam" document.
    - installing dependencies from a Git repository is a very common use case and is now covered
    - different ways of dealing with dune-project and .opam file are broken up in subsections, so that search results will display better when the Learn area search feature appears
    - PR: (doc) improve 'Managing Dependencies with opam' [ocaml/ocaml.org#1886](https://github.com/ocaml/ocaml.org/pull/1886)

  - Issue: Feature wish: OCaml syntax highlighting in README.md [ocaml-doc/voodoo#135](https://github.com/ocaml-doc/voodoo/issues/135)

  - PR Review:
    - APPROVED Update scraped data [ocaml/ocaml.org#1885](https://github.com/ocaml/ocaml.org/pull/1885#pullrequestreview-1797452437)
    - APPROVED Remove unreleased polymorphicvariants [ocaml/ocaml.org#1889](https://github.com/ocaml/ocaml.org/pull/1889#pullrequestreview-1799551077)
    - APPROVED Update scraped data [ocaml/ocaml.org#1888](https://github.com/ocaml/ocaml.org/pull/1888#pullrequestreview-1799551351)
    - APPROVED Ocaml playground tutorial [ocaml/ocaml.org#1880](https://github.com/ocaml/ocaml.org/pull/1880#pullrequestreview-1804183646)
    - APPROVED Add 2 XenServer positions again [ocaml/ocaml.org#1898](https://github.com/ocaml/ocaml.org/pull/1898#pullrequestreview-1805159769)
    - APPROVED Update scraped data [ocaml/ocaml.org#1893](https://github.com/ocaml/ocaml.org/pull/1893#pullrequestreview-1800152367)
    - APPROVED Update scraped data [ocaml/ocaml.org#1895](https://github.com/ocaml/ocaml.org/pull/1895#pullrequestreview-1801881067)
    - APPROVED Include @gmevel proof-reading of Seq tutorial [ocaml/ocaml.org#1376](https://github.com/ocaml/ocaml.org/pull/1376#pullrequestreview-1802008682)
    - COMMENTED Make changelog reachable from the landing page [ocaml/ocaml.org#1870](https://github.com/ocaml/ocaml.org/pull/1870#pullrequestreview-1803724887)
