kit-ty-kate week 2: 2024/01/08 -- 2024/01/14

# Projects

- Prototype a package management feature in Dune (Plat234)
- Opam annual minor releases: opam 2.2 (Plat111)
- General opam maintenance (Plat180)
- opam-repository PRs are promptly tested and merged (Plat125)

# Last Week

- Prototype a package management feature in Dune (Plat234)
  - @kit-ty-kate (1 day)
  - planning session
  - team meeting
  - Discussions on #team-build-system and at the team meeting about how dune package management actually works
    - we agreed to use opam-repository to store metadata about whether a package is relocable which forces people to fix their software and avoid the need for an opam-overlay

- Opam annual minor releases: opam 2.2 (Plat111)
  - @kit-ty-kate (3 days)
  - Have a deeper look at https://github.com/ocaml/opam/issues/5648
    - https://github.com/kit-ty-kate/ocaml-tar-playground
    - Review https://github.com/mirage/ocaml-tar/pull/127
    - Meet with @hannesm who might want to try and implement it
  - Finish, rebase and merge:
    - https://github.com/ocaml/opam/pull/5715
    - https://github.com/ocaml/opam/pull/5743
    - https://github.com/ocaml/opam/pull/5718
  - Prepare the 2.2.0~beta1 release:
    - https://github.com/ocaml/opam/pull/5779
  - Ask the infrastructure team what is the status of the Windows CI for opam-repository and if anyone can help do a temporary Github Action while this is getting fixed someday
    - Answers were negative due to the well known critical lack of people maintaining the infrastructure/CI
  - dev meeting
    - https://github.com/ocaml/opam/wiki/2024-Developer-Meetings#2024-01-10

- General opam maintenance (Plat180)
  - @kit-ty-kate (0.5 day)
  - Review https://github.com/ocaml/opam/pull/5778
  - Review https://github.com/ocaml/opam/pull/5780
  - Document common pitfalls on macOS:
    - https://github.com/ocaml/opam/issues/5784

- opam-repository PRs are promptly tested and merged (Plat125)
  - @kit-ty-kate (0.5 day)
  - Improve the time it takes to recompile opam.ocaml.org after each push in opam-repository
    - Review https://github.com/ocaml-opam/opam2web/pull/229
    - Speedup the cache checksum by using opam master instead of opam 2.0:
      - https://github.com/ocaml-opam/opam2web/pull/230
    - Do not rebuild staging.opam.ocaml.org everytime there is a change in opam-repository:
      - https://github.com/tarides/infrastructure/issues/285
    - Archives that are no longer accessible are dropped from the cache opam.ocaml.org:
      - https://github.com/tarides/infrastructure/issues/286
  - maintainers meeting
    - https://github.com/ocaml/opam-repository/wiki/Meeting-notes#20240110

- Miscellaneous (No KR)
  - @kit-ty-kate (0 day)
  - watch.ocaml.org is down:
    - https://github.com/ocaml/infrastructure/issues/89)
  - dune-release check does not support --include-submodules:
    - https://github.com/tarides/dune-release/issues/484

# Off contract notes:

Add support for git submodules in ocaml-release-script:
  - https://github.com/kit-ty-kate/ocaml-release-script/commit/783bb1f906be5f524ea2959223802a0a74fd218e

Release waylaunch.0.3.0:
  - https://github.com/ocaml/opam-repository/pull/25073

ocsf contract (5.2): 0 hour

# Next week

- Look for ways to improve the maintenance burden in opam-repository
- Look for ways to simplify onboarding of new opam-repository maintainers

# Issue and blockers

N/A
