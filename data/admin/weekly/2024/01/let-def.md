# Last week

- Improving syntax error messages for LR-parsers (PhD2)
  - @let-def (1 day)
  - Cleanups:
    - PR#11 uncovered opportunities for simplification in viable reductions
    - removed all code related to reachable reduction and enumeration from main code path
      (LRC is sufficient for DFA generation, no need to check for reachable failures at that point)
  - Fixed issue [#12](https://github.com/let-def/lrgrep/issues/12), yet another off-by-one

# Next week

- Finish working on coverage checks
- Continue writing down the new 
