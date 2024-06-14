n-osborne week 2: 2024/01/08 -- 2024/01/14

# Projects

- Gospel maintenance and improvements (#409)
- Battle test Gospel and Ortac (#1061)- Add Gospel support for Dune (#1062)
- Papers, talks, interviews, attendance at workshops (#968)

# Last Week

- Gospel maintenance and improvements (#409)
  - @n-osborne (2 days)
  - PR: Propagate non-optional name to typed ast (ocaml-gospel/gospel#374)
  - prepare and and conduct the Gospel type-checker dev meeting. We've discussed:
    - syntax for talking about exceptions in postconditions
    - Gospel handle ml files and bringing Cameleer to use the released Gospel
    - simplifying the way nested specifications are written (specification of a gospel logical function)

- Add Gospel support for Dune (#1062)
  - @n-osborne (2 days)
  - Continue experimenting on making Gospel closer to be integratable to Dune.
    Discussion with @let-def about reusing part of the OCaml parser.
    I am at the point where I can get rid of the ppx (for odoc), all the work
    being done at parsing. The user would then have to write just one
    preprocessing rule (for now the user have to use a ppx that takes the pps
    as argument).
    Discussion with @emillon raised that strong integration won't be possible
    until Gospel uses the official OCaml parser.

- Misc (No KR)
  - @n-osborne (1 days)
  - CSE meeting and preparation
  - team collective quarter planning
  - 1:1 with @jmid
