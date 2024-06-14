# Last Week

- Odoc has a search bar to search through the documentation  (Plat244)
  - @art-w (4 days)
  - Improve fuzzy type search, with case-insensitive substring matches (e.g. `hashtbl -> key seq` now works, while before only `Hashtbl.Make.t -> key Seq.t` was recognized.. and `list` now matches when `List.t` is used in the signature)
  - Optimize indexing time and database size for deeply nested types (which previously had exponential blowup)
  - Optimize search for small queries, by using a priority queue to explore only a subset of the entire suffix tree
  - Fix name sorting heuristics, as human-sensible priorities had been lost
  - Halve `sherlodoc.js` size by getting rid of unwanted dependencies (264Kb -> 92Kb, i.e. 32Kb compressed)
  - ~20% reduction in js database size (even after compression), from various small/easy gains
  - Fix bugs introduced by previous refactorings, also remove memory leak and fix ancient segfaults on statically allocated constants
  - Single opam package and executable, with dept-opts for less supported features (ancient, dream)
  - Lower ocaml version requirement from 4.14 to 4.08, and other opam packaging fixes
  - Add a `sherlodoc js` to produce `sherlodoc.js` dependency for integration with dune/odoc

- Provide permanent storage for MirageOS (Irm100)
  - @art-w (0.5 day)
  - Review Sooraj's final changes to the bitset datastructure https://github.com/tarides/notafs/pull/12
  - 1:1 with Sooraj to debrief the internship on his last day
  - Quick look at blog post by Bella https://docs.google.com/document/d/1pRn03v7JigC-cPKCW7f3jAv93MFmT57GVx8q8-xEpjk/edit?usp=sharing

- Other (No KR)
  - @art-w (0.5 day)
  - Quaterly planning meetings and report https://hackmd.io/i-gC-DENQbWxWTJPV6_82w
  - Team meetings, pep talk with Gwen regarding Eio switches... it's almost done!
  - Carbon14 internship preparation: for radiocarbon calibration, `OxCal` is a promising alternative to `calib` windows gui
  - Reaching out to leaving interns to organize a tech talk, and trying to set up safety nets to anticipate future interns talks as part of their internship
