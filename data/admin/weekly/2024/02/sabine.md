sabine week 2: 2024/01/08 -- 2024/01/14

# Projects

- Management (#1109)
- General ocaml.org maintenance (Plat187)
- Sunset opam.ocaml.org in favour of ocaml.org package documentation (Plat251)
- New version of the OCaml documentation (Plat194)
- Redesign OCaml.org Learn Area According to User Feedback (Plat278)

# Last Week

- Management (#1109)
  - @sabine (1.5 days)
  - quarterly planning
  - ocaml.org team meeting
  - reach out to ocamlwiki.com owner to find out what he plans to do to resolve the misinformation and porn ads on "recent changes" page
  - ocaml.org dev / community meeting
  - shakthi check-in
  - Q1 2024 alignment meeting
  - team brainstorming long term planning

- General ocaml.org maintenance (Plat187)
  - @sabine (2 days)

  - PR Review:
    - APPROVED Create laval.md [ocaml/ocaml.org#1904](https://github.com/ocaml/ocaml.org/pull/1904#pullrequestreview-1811474992)
    - APPROVED Fix broken links in CONTRIBUTING.md [ocaml/ocaml.org#1908](https://github.com/ocaml/ocaml.org/pull/1908#pullrequestreview-1811662008)
    - APPROVED Make changelog reachable from the landing page [ocaml/ocaml.org#1870](https://github.com/ocaml/ocaml.org/pull/1870#pullrequestreview-1811671987)
    - APPROVED Update scraped data [ocaml/ocaml.org#1910](https://github.com/ocaml/ocaml.org/pull/1910#pullrequestreview-1812712566)
    - COMMENTED implement darkmode on Learn/Excercise page [ocaml/ocaml.org#1902](https://github.com/ocaml/ocaml.org/pull/1902#pullrequestreview-1813097471)
    - COMMENTED removed packages-home.png [ocaml/ocaml.org#1916](https://github.com/ocaml/ocaml.org/pull/1916#pullrequestreview-1815281837)
    - APPROVED Update scraped data [ocaml/ocaml.org#1915](https://github.com/ocaml/ocaml.org/pull/1915#pullrequestreview-1815282493)
    - APPROVED Implement dark mode on get started and language [ocaml/ocaml.org#1913](https://github.com/ocaml/ocaml.org/pull/1913#pullrequestreview-1815914351)
    - APPROVED Render the Author of a Blog Post and the Source [ocaml/ocaml.org#1619](https://github.com/ocaml/ocaml.org/pull/1619#pullrequestreview-1816059570)
    - APPROVED removed packages-home.png [ocaml/ocaml.org#1918](https://github.com/ocaml/ocaml.org/pull/1918#pullrequestreview-1816074360)
    - APPROVED Implement dark mode on Learn/Platform Tools [ocaml/ocaml.org#1919](https://github.com/ocaml/ocaml.org/pull/1919#pullrequestreview-1817621435)
    - APPROVED Fix typos in 1st program tutorial [ocaml/ocaml.org#1924](https://github.com/ocaml/ocaml.org/pull/1924#pullrequestreview-1818182180)
    - APPROVED Fix small typo on getting started page [ocaml/ocaml.org#1926](https://github.com/ocaml/ocaml.org/pull/1926#pullrequestreview-1818559211)
    - APPROVED Remove links to V2 in docs [ocaml/ocaml.org#1925](https://github.com/ocaml/ocaml.org/pull/1925#pullrequestreview-1818576484)
    - COMMENTED fix: Prevent docs link for packages without docs [ocaml/ocaml.org#1927](https://github.com/ocaml/ocaml.org/pull/1927#pullrequestreview-1818883442)
    - APPROVED add recommended_next_tutorials capability [ocaml/ocaml.org#1928](https://github.com/ocaml/ocaml.org/pull/1928#pullrequestreview-1819957682)

  - Closed and merged a lot of open PRs. Fix small issues introduced when merging or rebasing open PRs:
    - PR: Fix language manual banner HTML [ocaml/ocaml.org#1922](https://github.com/ocaml/ocaml.org/pull/1922)
    - PR: Gitignore *:OECustomProperty [ocaml/ocaml.org#1937](https://github.com/ocaml/ocaml.org/pull/1937)

  - PR: Prepend opam exec -- on all dune commands [ocaml/ocaml.org#1905](https://github.com/ocaml/ocaml.org/pull/1905)
  - PR: (doc) Mention in CONTRIBUTING.md how to add images [ocaml/ocaml.org#1906](https://github.com/ocaml/ocaml.org/pull/1906)

  - wrote Email to Florian and Gabriel about creating a github repo for the OCaml compiler manuals

  - when docs-data.ocaml.org is unreachable, ocaml.org would fail without even showing an error page - now it fails more gracefully - but this is still pretty bad because there's so many failing requests going out
    - PR: in case docs-data.ocaml.org is unreachable, fail more gracefully [ocaml/ocaml.org#1939](https://github.com/ocaml/ocaml.org/pull/1939)

- Onboard New Contributors to OCaml Projects (New KR)
  - @sabine (1 day)
  - streaming on twitch.tv/sabine_ocaml
    - continuing trying to fix https://github.com/ocaml-doc/voodoo/issues/129 - creating a dune package to test singleton / wrapped / unwrapped library names
    - added the new test package as a test case to ocaml-doc/voodoo
    - PR: Read Library Names from Packages Correctly [ocaml-doc/voodoo#136](https://github.com/ocaml-doc/voodoo/pull/136)
    - PR: Move h1 Title Rendering to the Correct Location [ocaml-doc/voodoo#137](https://github.com/ocaml-doc/voodoo/pull/137)
    - pushed PRs to ocaml-doc/voodoo staging branch so that the three patches (Guillaume's odoc 2.4.0 update and my two patches from the streams) can be tested on the staging docs pipeline

- New version of the OCaml documentation (Plat194)
  - @sabine (0.5 days)
  - close outdated/obsolete documentation PRs

  - APPROVED Create tutorial: Running Commands in an Opam Switch [ocaml/ocaml.org#1825](https://github.com/ocaml/ocaml.org/pull/1825#pullrequestreview-1809596561)
  - APPROVED (doc) Improve Toplevel Instructions [ocaml/ocaml.org#1698](https://github.com/ocaml/ocaml.org/pull/1698#pullrequestreview-1816064164)
  - COMMENTED Update Modules and Functors Tutorials [ocaml/ocaml.org#1778](https://github.com/ocaml/ocaml.org/pull/1778#pullrequestreview-1820043854)
  - APPROVED Update labelled arguments tutorial [ocaml/ocaml.org#1881](https://github.com/ocaml/ocaml.org/pull/1881#pullrequestreview-1818312305)
  - COMMENTED Create DOCUMENTATION_WRITING.md [ocaml/ocaml.org#1912](https://github.com/ocaml/ocaml.org/pull/1912#pullrequestreview-1815287980)
  - PR: (doc) Remove 'Functional Programming' document [ocaml/ocaml.org#1940](https://github.com/ocaml/ocaml.org/pull/1940)
