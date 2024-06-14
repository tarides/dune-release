Hari Hara Naveen week 52: 2023/01/8 -- 2023/01/12

# Projects

- Addressing TSan alarms in OCaml's runtime system (internship) (#1072)

# Last Week

- Addressing TSan alarms in OCaml's runtime system (internship) (#1072)
  - @hhn (5 days)
  - Discussed fix with mentor (Olivier Nicole) and concluded it is a false race according to LKMM
  - Decided to silence the false positive using `AnnotateHappensBefore` and `AnnotateHappensAfter`
  
