polytypic week 1: 2024/01/01 -- 2024/01/07

# Projects

- Benchmarking Saturn Structures (#1088)
- General Multicore Applications maintenance (#401)
- MC104: Saturn (#362)
- Com21: Mentoring: Internal internships and projects (#354)

# Last Week

- Benchmarking Saturn Structures (#1088)

  - @polytypic (2.5 days)

  - PR: Benchmark parallel CMP using various number of domains
    [ocaml-multicore/kcas#174](https://github.com/ocaml-multicore/kcas/pull/174)
  - PR: Use a wall time budget for benchmarks
    [ocaml-multicore/kcas#177](https://github.com/ocaml-multicore/kcas/pull/177)
  - PR: Add fields on statistics to benchmark JSON
    [ocaml-multicore/kcas#178](https://github.com/ocaml-multicore/kcas/pull/178)
  - PR: Move bench framework to `multicore-bench` project
    [ocaml-multicore/kcas#179](https://github.com/ocaml-multicore/kcas/pull/179)

  - I worked on improvements the internal multicore benchmarking framework used
    in Kcas as a part of extracting that into a separate library,
    [multicore-bench](https://github.com/ocaml-multicore/multicore-bench), with
    the goal of using it in Saturn, Kcas, and other multicore libraries we have.

- General Multicore Applications maintenance (#401)

  - @polytypic (1.5 days)

  - Issue: `EBADF` in timeout test
    [ocaml-multicore/domain-local-timeout#16](https://github.com/ocaml-multicore/domain-local-timeout/issues/16)

  - I noticed the `EBADF` error on Kcas CI a couple of times and realized that
    there is likely a race condition related to domain termination in the
    domain-local-timeout library.

  - PR: WIP: Two stack queue
    [ocaml-multicore/kcas#175](https://github.com/ocaml-multicore/kcas/pull/175)

  - Inspired by the new queue algorithm I
    [initially prototyped for Saturn](https://github.com/ocaml-multicore/saturn/pull/112)
    I created a PR to Kcas with a similar design. Just like with the Saturn
    version, the 2-stack queue turned out to be faster than previous queues
    developed for Kcas.

  - PR: Make the `Loc` constructor private
    [ocaml-multicore/kcas#180](https://github.com/ocaml-multicore/kcas/pull/180)

  - Additional safety measure to discourage misuse. The reason for (previously)
    exposing the "shape" of a `Loc.t` is to work around the `float array`
    pessimization of the OCaml compiler.

  - PR: Add `Dllist` benchmark
    [ocaml-multicore/kcas#176](https://github.com/ocaml-multicore/kcas/pull/176)
  - PR: Use tagged GADT with better naming for the internals of `Dllist`
    [ocaml-multicore/kcas#181](https://github.com/ocaml-multicore/kcas/pull/181)
  - PR: Group operations in the `Dllist` signature
    [ocaml-multicore/kcas#182](https://github.com/ocaml-multicore/kcas/pull/182)
  - PR: Expose `Dllist` type to allow matchable cursors
    [ocaml-multicore/kcas#183](https://github.com/ocaml-multicore/kcas/pull/183)

  - I improved the Kcas `Dllist` a bit as Charlene, interning in the Irmin team,
    was using Kcas in an experiment to create a new LRU cache.

- MC104: Saturn (#362)

  - @polytypic (0.5 days)

  - COMMENTED Lock free hash table
    [ocaml-multicore/saturn#117](https://github.com/ocaml-multicore/saturn/pull/117#pullrequestreview-1803196585)

  - Brief look at Carine's hash table work.

- Com21: Mentoring: Internal internships and projects (#354)

  - @polytypic (0.5 days)

  - COMMENTED Updated the MPSC queue implementation with the version from picos
    and the tests
    [ocaml-multicore/saturn#118](https://github.com/ocaml-multicore/saturn/pull/118#pullrequestreview-1800165654)

  - Mentoring and review of Laasya's work on bringing the 2-stack MPSC queue to
    Saturn.
