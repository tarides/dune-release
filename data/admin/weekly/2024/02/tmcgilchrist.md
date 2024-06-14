tmcgilchrist week 2: 2024/01/08 -- 2024/01/14

# Projects

- General maintenance of OCaml including OCaml PR reviews (#953)
- Improve debugging experience on MacOS (#1102)
- Other tasks (No KR)

# Last Week

- General maintenance of OCaml including OCaml PR reviews (#953)
  - @tmcgilchrist (1 days)
  - Code review for arm64 backend: tweak specific_operation names [ocaml/ocaml#12890](https://github.com/ocaml/ocaml/pull/12890)
  - Code review on TSan for POWER  https://github.com/ocaml/ocaml/pull/12876

- Improve debugging experience on MacOS (#1102)
  - @tmcgilchrist (1 days)
  - Working on olly / runtime_events_tools. Fixing [olly sometimes fails to create cursor](https://github.com/tarides/runtime_events_tools/issues/33) and perhaps the M1/ARM64 error in the test suite. Fix ARM64 installation error https://github.com/tarides/runtime_events_tools/issues/27.

  - Investigating debugger support for OCaml on MacOS with Mach-O and dSYM. Looking at code generated with CFI/DWARF infomation on the platform and deconstructing Mach-O binaries with platform tooling. Might need something better to handle Mach-O binaries for OCaml. Found a few interesting Rust tools for working with binaries:
    - Rust library for reading ELF/Mach/PE binaries https://github.com/m4b/goblin
    - Cute Rust tool for visualising ELF files https://github.com/kevin-lesenechal/elf-info
    - Gimili: A library for reading and writing the DWARF debugging format https://github.com/gimli-rs/gimli/tree/master

- Other tasks (No KR)
  - @tmcgilchrist (3 days)
  - Compiler runtime team meeting for Q1 and preparation for personal tasks for the quarter. (4 hours)
  - Follow up on preparing release to opam [ocaml-multicore/hdr_histogram_ocaml#8#pullrequestreview-1812173380](https://github.com/ocaml-multicore/hdr_histogram_ocaml/pull/8) and [ocaml/opam-repository#25059](https://github.com/ocaml/opam-repository/pull/25059).

  - Reading on Unikraft scope of work proposal and general background on Unikraft. 2 hours
  - Gathering notes on OCaml Performance and Optimisation https://hackmd.io/oXISHViJSxy23YN3x-o7Lw?view and catchup with KC about performance tooling. Outcome was some areas to focus on, and to talk to Jane Street about what areas they would like improved and are working on.
    - Reading Tracing for Eio propsal https://docs.google.com/document/d/1gWbX2zgQejI3vIpZzpclQlpYrTLUJ6sFDHBQf63FiCY/edit which should cover more general custom tracing events visualisation for a larger range of tools than just EIO.
  - Performance testing tsan on macos on both ARM64 and X86_64. Short version a new M3Pro with 12 cores takes 15 minutes to run the parallel testsuite compared to 46 minutes on X86_64 with 6 cores.

# Next Week

- Work on JaneStreet proposals for performance
- Work on JaneStreet proposals for native debugging support
- Finish TSan on Power review
