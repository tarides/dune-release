emillon week 2: 2024/01/08 -- 2024/01/14

# Last Week

- Technical blog posts (Com19)
  - @emillon (0.5 days)
  - Solvuu post: first draft of what we did on awsm

- Lock Directory Generation and Dune Context Extensions (#1068)
  - @emillon (1 day)
  - ocamlfind relocatability:
    - tweaked build instructions to get a relocatable ocamlfind (in surface only)
    - access through findlib does not look necessary
    - but access through topfind is, to unlock topkg
  - PR: pkg: use a `Code_error` instead of assert false [ocaml/dune#9719](https://github.com/ocaml/dune/pull/9719)
  - PR: pkg: support write-file in expander [ocaml/dune#9720](https://github.com/ocaml/dune/pull/9720)

- General dune maintenance (Plat140)
  - @emillon (1.5 days)
  - PR: refactor(engine): check config once in maybe_async [ocaml/dune#9696](https://github.com/ocaml/dune/pull/9696)
  - 3.13 release:
    - Branched 3.13 and released alpha1.
    - PR: chore: merge 3.12.2 changelog [ocaml/dune#9721](https://github.com/ocaml/dune/pull/9721)
    - PR: chore: prepare 3.13.0~alpha1 [ocaml/dune#9722](https://github.com/ocaml/dune/pull/9722)
    - Issue: 3.13.0 release tracking [ocaml/dune#9695](https://github.com/ocaml/dune/issues/9695)
    - PR: [new release] dune (15 packages) (3.13.0~alpha1) [ocaml/opam-repository#25067](https://github.com/ocaml/opam-repository/pull/25067)

- General opam maintenance (Plat180)
  - @emillon (1 day)
  - Investigated why `opam2web` is slow. One important part is reverse conflicts that are expensive, but are not super useful:
    - PR: Package pages: do not display reverse conflicts [ocaml-opam/opam2web#229](https://github.com/ocaml-opam/opam2web/pull/229)
  - Other parts can be sped up (some hash computations are redundant) but that is not as big a win.

- Admin (No KR)
  - @emillon (1 day)
  - Q1 Planning meeting
  - Dune dev meeting
  - Build system team meeting
