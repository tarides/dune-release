dra27 week 02: 2024/01/08 -- 2024/01/14

# Projects

- General maintenance of OCaml including OCaml PR reviews (Comp65 / #953)
- OCaml compiler installations are relocatable (Comp82 / #949)
- Restore the MSVC port (#1063)
- opam 2.2 (Plat111 / #48)
- opam packaging for the compiler (#1065)

# Last Week

- General maintenance of OCaml including OCaml PR reviews (#953)
  - @dra27 (0.5 days)
  - Catch-up on `publish.ml` failure on Windows - hit its annual Stale bot ping
    ([ocaml/ocaml#11853][])
  - Sweeping new PRs; daringly entered Slack discussion on Unix FDs as `int`
    with historical relation to [ocaml/ocaml#1990][].
  - Rebased [ocaml/ocaml#11792][] and started to update the script to be
    something less awful and written in OCaml - similarly prodded by an annual
    Stale bot ping. This is a CI utility to switch the synchronisation of the
    documentation for the Labels modules in the Standard Library to be linted,
    rather than generated, as the generator is the cause of some not
    inconsiderable development pain.
  - Bi-weekly Cambridge Compiler team lunch
  - Bi-weekly triage meeting

[ocaml/ocaml#11853]: https://github.com/ocaml/ocaml/issues/11853
[ocaml/ocaml#1990]: https://github.com/ocaml/ocaml/pull/1990
[ocaml/ocaml#11792]: https://github.com/ocaml/ocaml/pull/11792

- Restore the MSVC port (#1063)
  - @dra27 (0 days)
  - Slack discussions and emails

- opam packaging for the compiler (#1065)
  - @dra27 (0.5 days)
  - Getting ducks lined up 🦆
  - Work from Q3 last year led to a prototype branch which had various WIP/TODO
    commits in it. Problem with that is that it has all the work to be done with
    no explanations!
  - Comparison matrix ensuring that the commits in the `windows-5.0` test branch
    are either copied to the `windows-compilers` dev branch _or_ have a
    justifiable alternative. Small amount of time spent confirming a TODO item
    on why a CRLF patch is presently in the `windows-5.0` branch only.
    Explanation confirmed and updated, with two issues opened in opam on the
    way.
  - Preliminary documentation of the current state of compiler packages written.
  - Various task list items extracted on the way, and opam 3.x possible features
    to improve things further.
  - Next week
    - Expand the task list and validate it against the Q3 WIP branch
    - Possibly prototype all the packaging suggestions
    - Definitely produce point-by-point failure mode / issue which leads to the
      suggestion for each change (i.e. justifications)

- Migrate compiler from opam-repository-mingw (#37)
  - @dra27 (0 days)
  - Discussions surrounding opam-repo-ci and bulk testing requirements for
    post-opam 2.2.

- opam 2.2 (#48)
  - @dra27 (1 day)
  - Investigations (and a rabbithole) with [ocaml/opam#5715][]. PR deals with
    the unusual case of needing to output strings from a native Windows binary
    which do _not_ use CRLF endings, as they are then used in Unix shells
    (i.e. `eval $(opam env)` should work in Cygwin's `bash` from a native
    Windows opam). The original PR is @rjbou's, but it's gone through various
    iterations and has settled on a relatively simple approach using `Unix.dup`,
    via additions to the Standard Library and some complex mutex trickery.
  - Weekly core dev meeting
  - Some preliminary investigations into fast file extraction on Windows,
    related to discussions from the dev meeting looking at avoiding tarball
    extraction for opam-repository (which has long been on the Windows TODO
    list, but is becoming increasingly relevant on all platforms). The
    conclusion so far (based on work already done in `rustup` in 2019) is that
    we may well be able to get Windows Defender to back-off when we extract
    tarballs for _sources_ by ensuring files written by opam are scan-on-read
    instead of the default scan-on-close (which the `rustup` devs got added as
    an exception for Defender), but this won't help the repository un-tarring,
    as of course having extracted it opam is very shortly going to read it.
    Suggests that for Windows, while we may want to be checking and improving
    the parallelism of I/O (as with `rustup`, there are clear improvements to be
    made by offloading some syscalls to thread pools), we do also want to
    continue down the "not writing files which don't need to be written"
    approach, too.
  - Tracked issues in opam 2.2 for Windows arising from compiler packaging
    updates (general issues in opam, not specifically blocking the packaging):
    - opam's internal Cygwin installation needs to set `noacl` for the
      `cygdrive` mount to avoid the risk of spurious permissions denied errors
      coming from Cygwin commands (especially `install`) being used on
      non-Cygwin directories in the opam root. ocaml-dockerfile has long-since
      had to deal with this as well ([ocaml/opam#5781][]).
    - opam should ensure that it runs with `CYGWIN=winsymlinks:native` to
      maximise the chances of tarballs extracting correctly on dev machines
      ([ocaml/opam#5782][]).

[ocaml/opam#5715]: https://github.com/ocaml/opam/pull/5715
[ocaml/opam#5781]: https://github.com/ocaml/opam/issues/5781
[ocaml/opam#5782]: https://github.com/ocaml/opam/issues/5782

- OCaml compiler installations are relocatable (#949)
  - @dra27 (0.5 days)
  - Determined a possible alternate scheme for `-set-global-string` to
    experiment with the `enable-relative` branch is next worked on. Insight came
    from discussions bringing back up [ocaml/ocaml#1990][] and the idea to
    initialise additional known FDs on startup. The theory here would be to move
    the default for `caml_standard_library_default` to be controllable from
    `OCAMLRUNPARAM`. This leads to the idea that instead of providing a
    mechanism for inserting arbitrary data symbols into the executable (which is
    the current `-set-global-string`), that instead a mechanism to persist the
    _defaults_ for `OCAMLRUNPARAM` could be added. That's potentially much more
    useful (for example, changing default stack and GC parameters, etc.). It
    also leads much more naturally to a solution allowing runtime-tendered
    bytecode images to specify these parameters via a new section in the
    bytecode executable format, which lifts the limitation of
    `-set-global-string` not applying to these tendered/shebang executables
    (this could have been done with the existing design, but it would have felt
    quite forced - the ability to specify runtime parameters on the other hand
    fits quite naturally with the already existing `RNTM` section to specify the
    runtime).
  - Actual output at this stage was simply updating the journal for relocatable:
    this is Q2 work.

[ocaml/ocaml#1990]: https://github.com/ocaml/ocaml/pull/1990

- Meet (#1082)
  - @dra27 (1.5 days)
  - Meetings, interactions, idle brain-cycles, etc.
