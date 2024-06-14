Hari Hara Naveen week 52: 2023/01/01 -- 2023/01/07

# Projects

- Addressing TSan alarms in OCaml's runtime system (internship) (#1072)

# Last Week

- Addressing TSan alarms in OCaml's runtime system (internship) (#1072)
  - @hhn (5 days)
  - Found lack of happens before (hb) relatioship between pool_initialize / oldify_one
  - Came up with fix to establish hb relatioship according to C11 Memory Model
  