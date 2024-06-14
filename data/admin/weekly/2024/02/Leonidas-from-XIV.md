Leonidas-from-XIV week 2: 2024/01/08 -- 2024/01/14

# Projects

- Dune

# Last Week

- Dune Source Fetching and Multiple Opam-repositories Support (#1069)
  - @Leonidas-from-XIV (5 days)
  - COMMENTED refactor(pkg): leave CR for untimely update
    [ocaml/dune#9640](https://github.com/ocaml/dune/pull/9640#pullrequestreview-1808388817)
    clarifying the comment, which ultimately lead to the removal of the
    `--skip-update` option
  - APPROVED refactor(pkg): improve file io in sys_poll
    [ocaml/dune#9649](https://github.com/ocaml/dune/pull/9649#pullrequestreview-1808539296)
  - APPROVED fix(pkg): pass locations to [Opam_repo.Source] and to command line
    [ocaml/dune#9642](https://github.com/ocaml/dune/pull/9642#pullrequestreview-1808698127)
  - APPROVED fix(pkg): save locations of repo names
    [ocaml/dune#9663](https://github.com/ocaml/dune/pull/9663#pullrequestreview-1810787740)
  - APPROVED refactor(pkg): share results between sys poll vars
    [ocaml/dune#9666](https://github.com/ocaml/dune/pull/9666#pullrequestreview-1810888468)
  - APPROVED fix(pkg): directory_entries bug
    [ocaml/dune#9669](https://github.com/ocaml/dune/pull/9669#pullrequestreview-1810927468)
  - COMMENTED fix(pkg): improve locations for local path repos
    [ocaml/dune#9670](https://github.com/ocaml/dune/pull/9670#pullrequestreview-1810932687)
  - APPROVED fix(pkg): missing location in rev store
    [ocaml/dune#9681](https://github.com/ocaml/dune/pull/9681#pullrequestreview-1810943354)
  - APPROVED fix(pkg): add more missing locations
    [ocaml/dune#9694](https://github.com/ocaml/dune/pull/9694#pullrequestreview-1812867360)
  - COMMENTED pkg: enforce opam-compatible package names
    [ocaml/dune#9689](https://github.com/ocaml/dune/pull/9689#pullrequestreview-1813402058)
  - COMMENTED pkg: don't generate checksums for local sources
    [ocaml/dune#9703](https://github.com/ocaml/dune/pull/9703#pullrequestreview-1815254855)
  - APPROVED refactor(pkg): make remote reading a little more resilient
    [ocaml/dune#9698](https://github.com/ocaml/dune/pull/9698#pullrequestreview-1817733298)
  - APPROVED pkg: simple end to end test of package management
    [ocaml/dune#9718](https://github.com/ocaml/dune/pull/9718#pullrequestreview-1817761995)
  - PR: Remove `--skip-update` and make it implied when possible
    [ocaml/dune#9683](https://github.com/ocaml/dune/pull/9683) as
    `--skip-update` would only work in very specific cases. In other cases it
    would just break, thus the behavior is now implicit if it is one of the
    cases where `--skip-update` would work and disabled in the cases where it
    would previously break.
  - PR: fix(pkg): Use function return value
    [ocaml/dune#9693](https://github.com/ocaml/dune/pull/9693) as a follow up
    to [ocaml/dune#9670](https://github.com/ocaml/dune/pull/9670)
  - More work on submodules, fitting them into `Rev_store.At_rev` to be able to
    transparently get the contents of a git repo that's a submodule
