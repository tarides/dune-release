jmid week 1: 2024/01/01 -- 2024/01/07

# Projects

- Property-Based Testing for Multicore (#1090)
- General maintenance of OCaml including OCaml PR reviews (Comp65)
- QCheck maintenance and improvements (Comp98)

# Last Week

- Property-Based Testing for Multicore (#1090)
  - @jmid (1 days)
  - PR to separate 5.2 and 5.3+trunk workflows now that 5.2 has branched: [ocaml-multicore/multicoretests#429](https://github.com/ocaml-multicore/multicoretests/pull/429)
    As a bonus this avoids double push+PR runs thus reducing CI runs.
  - PR to add a 5.3+trunk+win package to custom repo [shym/custom-opam-repository#8](https://github.com/shym/custom-opam-repository/pull/8)
  - Trying to trigger `Out_channel` crash with a bytecode executable. It seem rare:
    - No luck when building .bc under a normal 5.1.1 switch
    - No luck when running under a dedicated 5.3+trunk bytecode switch
    - Failing to build a 32-bit switch
      No luck in reproducing bug when using pre-built 5.1.1/5.2 Docker-images instead
  - Quick PR to disable Lin Out_channel tests under FreeBSD as
    they are a source of false alarms [ocaml-multicore/multicoretests#430](https://github.com/ocaml-multicore/multicoretests/pull/430)
  - Dusted off old `io-stm-tests` branch with `STM` `Out_channel` test.
    - Updated `length` and `position` accordingly
    - Added `cmd`s to reach feature parity with `Lin` tests:
      - `seek`, `close_no_err`, `output_byte`
      - `output_bytes`, `output` `output_substring`
      - `is_buffered`, `set_buffered`, `set_binary_mode` cmds
    - Adjust weights and clean up code
    - Fixed `set_binary_mode` on MinGW and Cygwin
    - Resulting PR: [ocaml-multicore/multicoretests#431](https://github.com/ocaml-multicore/multicoretests/pull/431)

- General maintenance of OCaml including OCaml PR reviews (Comp65)
  - @jmid (0.5 days)
  - Looked more into `caml_thread_interrupt_hook` and `caml_thread_yield` following Mark's message on `#multicore`
    Built a 5.1.1 with Mark's patch and ran `multicoretests` to confirm the patch.
  - Created a branch to test run Mark's Systhread root registration
    PR https://github.com/ocaml-multicore/multicoretests/tree/try-pr12861-systhread-root
  - Minor rabbit hole: attempting to build an FLambda2 compiler to run selected `multicoretests` on it
  - Small PR to update compiler opam file dependency to 5.3 after branching 5.2 [ocaml/ocaml#12880](https://github.com/ocaml/ocaml/pull/12880)

- Time off (No KR)
  - @jmid (2 days)
  - Off Monday+Tuesday

# Other
- @jmid (1.5 days)
- Q1 planning, trying to get an overview (Unicraft, Ephemeron revision, ...)
- Calendar updates
- Meetings
  - 1:1 with Riku
  - Team lead meeting
  - CompLang team meeting

# Next Week

- Q1 planning
