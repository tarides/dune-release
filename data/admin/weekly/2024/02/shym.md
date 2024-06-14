shym week 2: 2024/01/08 -- 2024/01/14

# Projects

- Property-Based Testing for Multicore (#1090)
- Restore the MSVC port (#1063)
- Gospel maintenance and improvements (Comp126)
- Bring up and evaluate the options of OCaml 5 Mirage backends (#1092)
- Proposal writing (No WI)

# Last Week

- Property-Based Testing for Multicore (#1090)
  - @shym (0.5 days)
  - Reviewed the addition of `Out_channel` STM tests, in particular looking for
    cases that were tested with the Lin tests but not yet tested with the STM
    tests
    [ocaml-multicore/multicoretests#431](https://github.com/ocaml-multicore/multicoretests/pull/431#pullrequestreview-1813886634),
    [ocaml-multicore/multicoretests#431](https://github.com/ocaml-multicore/multicoretests/pull/431#issuecomment-1888854600)
  - Reviewed “Disable Lin Out_channel test under FreeBSD”
    [ocaml-multicore/multicoretests#430](https://github.com/ocaml-multicore/multicoretests/pull/430#pullrequestreview-1808875295)

- Gospel maintenance and improvements (Comp126)
  - @shym (0 days)
  - Attended the remote Gospel developer meeting
  - Reviewed “Propagate non-optional name to typed ast”
    [ocaml-gospel/gospel#374](https://github.com/ocaml-gospel/gospel/pull/374#pullrequestreview-1813074918)

- Restore the MSVC port (#1063)
  - @shym (2 days)
  - Reviewed the various places in which the OCaml code base is using atomic
    pointers and pointer to atomic values to check whether `cl` 19.38.33133 is
    producing correct assembly code for them (my previous review was on a
    preview version of that compiler); in most cases the code is currently using
    explicit atomic load and store operations (such as `atomic_load_acquire`,
    etc.) rather than a simple access and relying on the compiler to use the
    proper atomic operation; all in the accesses seem to be compiled correctly
  - Tested whether the part of the branch that changes the way custom runtime is
    compiled could be spawned off and didn’t break the other ports
  - Discussed with @dra27 about the last steps to go through before opening the
    PR
  - Reviewed the latest versions of @MisterDA’s branch that brings MSVC
    compatibility to `winpthreads`, in particular by testing them through the
    compiler test suite which showed a couple of issues for the 32-bit port

- Bring up and evaluate the options of OCaml 5 Mirage backends (#1092)
  - @shym (1.5 days)
  - Started to read about unikraft, in particular Christiano’s writeup
  - Started to review the PR adding support for OCaml 5 in Solo5, reading
    through the commits to understand what is at stake, which also required in
    turn reading a bit more about Solo5, etc.

- Proposal writing (No WI)
  - @shym (0 days)
  - Reviewed a proposal for our property-based testing work

- Misc (No WI)
  - @shym (1 days)
  - Quarter planning
  - Started to prepare 2023 year review
  - Meetings and talks:
    - 1:1 with @jmid
    - Compiler meeting
