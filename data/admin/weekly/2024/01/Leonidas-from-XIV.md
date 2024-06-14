Leonidas-from-XIV week 1: 2024/01/01 -- 2024/01/07

# Projects

- Dune

# Last Week

- Dune Source Fetching and Multiple Opam-repositories Support (#1069)
  - @Leonidas-from-XIV (4 days)
  - APPROVED pkg: store vars in commnad filters in metadata
    [ocaml/dune#9561](https://github.com/ocaml/dune/pull/9561#pullrequestreview-1800186783)
  - APPROVED fix(pkg): read default branch correctly
    [ocaml/dune#9617](https://github.com/ocaml/dune/pull/9617#pullrequestreview-1803707678)
    fixes a bug in the parser. Also helped me understand the semantics of
    `split_while` better, as if solved an issue I had when working on
    submodules.
  - APPROVED test(pkg): test local rev store
    [ocaml/dune#9619](https://github.com/ocaml/dune/pull/9619#pullrequestreview-1803779964)
    makes all tests use a local revision store instead of accidentally using
    the users revision store
  - PR: refactor(pkg): Use the XDG cache dir that the helpers set up
    [ocaml/dune#9621](https://github.com/ocaml/dune/pull/9621) follow up to
    issue 9619 the opam-repository-download test was using its own cache but
    with the cache defined in issue 9619 there is no need for that anymore so
    it can use the same cache as the other tests
  - APPROVED refactor(pkg): move global rev_store to [Rev_store]
    [ocaml/dune#9616](https://github.com/ocaml/dune/pull/9616#pullrequestreview-1803844395)
    moves the global revision store to a location that's accessible from
    everywhere, thus the access to the global is simpler for every API
  - APPROVED fix(pkg): improve url validation in repos
    [ocaml/dune#9620](https://github.com/ocaml/dune/pull/9620#pullrequestreview-1804473197)
    parses URLs earlier
  - APPROVED fix(pkg): force repos to use git:// prefix for git
    [ocaml/dune#9628](https://github.com/ocaml/dune/pull/9628#pullrequestreview-1805555057)
    removes the fallback to use Git when specifying HTTP URLs
  - APPROVED fix(pkg): add url validation to package sources
    [ocaml/dune#9631](https://github.com/ocaml/dune/pull/9631#pullrequestreview-1805555700)
  - PR: fix(pkg): Fix conditional dependencies test failure
    [ocaml/dune#9592](https://github.com/ocaml/dune/pull/9592) fixes a test
    that was using the default repositories by accident instead of stubbing
    them out
  - PR: refactor(pkg): Remove `Repository_id`
    [ocaml/dune#9614](https://github.com/ocaml/dune/pull/9614) now that we only
    support Git sources they can be specified by adding the hash to the URL
    instead of a special revision ID type, thus it can be eliminated
  - Working on submodule support: currently parsing the `.gitmodule` format to
    determine locations and URLs of submodules

- Vacation (No KR)
  - @Leonidas-from-XIV (1 day)
  - New Years Day, everyone's resting
