jmid week 2: 2024/01/08 -- 2024/01/14

# Projects

- Property-Based Testing for Multicore (#1090)
- General maintenance of OCaml including OCaml PR reviews (Comp65)
- QCheck maintenance and improvements (Comp98)

# Last Week

- Property-Based Testing for Multicore (#1090)
  - @jmid (1 days)
  - CI summary and merge PR to separate 5.2 workflows https://github.com/ocaml-multicore/multicoretests/pull/429
  - Address Samuel's review on https://github.com/ocaml-multicore/multicoretests/pull/431
    Extend `Out_channel` `STM` tests to generate `close*`-`cmd`s in state `Closed` too.
    Extend it further to allow all `cmd`s (except open) in state `Closed`.
    This triggered failures in all `5.2` and `trunk` (not seen locally on `5.1.1`)
    indicating a regression on repeatedly outputting to a closed `Out_channel`

- General maintenance of OCaml including OCaml PR reviews (Comp65)
  - @jmid (0 days)
  - Write David about `dune` failing to build on `trunk` under macOS

# Other
- @jmid (4 days)
- Draft a Q1 plan https://github.com/tarides/goals/pull/564
- Internship candidate discussion
- Adjustments the to PBT proposal
- Meetings
  - Q1 team planning meeting
  - Q1 pillar planning discussion meeting
  - Q1 plan alignment meeting
  - 1:1 Nicolas, Olivier, Samuel, Fred, Miod, Jerome, Riku, Hari
  - Multicore/Comp65 stand-up

# Next Week

- Some year-end-discussion meetings
- Prepare slide(s) for company-wide Q1 plan presentation
- Report `Out_channel` regression
