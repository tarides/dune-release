OlivierNicole week 2: 2024/01/08 -- 2024/01/14

# Projects

- General maintenance of OCaml including OCaml PR reviews (Comp65)
- Close the JSOO performance gap (Comp120)
- Address all known runtime races reports (New KR)
- Mentoring: Internal internships and projects (Com21)

# Last Week

- General maintenance of OCaml including OCaml PR reviews (Comp65)
  - @OlivierNicole (0.5 days)
  - Comp65 meeting and ocaml/ocaml triaging meeting

- Close the JSOO performance gap (Comp120)
  - @OlivierNicole (1.5 days)
  - I ran benchmarks of generators based on effect handlers to test the impact of the double translation PR ocsigen/js_of_ocaml#1461, as suggested by @lpw25 and @kayceesrk. It shows that double translation allows code that does not use effect handlers to run at full speed, whereas currently functions in CPS can slow down unrelated code. I summarized the benchmarks results at <https://github.com/ocsigen/js_of_ocaml/pull/1461#issuecomment-1889593948>.

- Address all known runtime races reports (#1059)
  - @OlivierNicole (2 days)
  - Investigate the data races on which @Johan511 works for his internship. I did some debugging to confirm that the report is indeed a data race in C11, but is not a real data race in practice, e.g. if you reason in the Linux Kernel Memory Model (LKMM). For this reason, we should use silencing or annotations to remove the report.

- Mentoring: Internal internships and projects (Com21)
  - @OlivierNicole (0.5 days)
  - CHANGES_REQUESTED Fixes a false warning thrown when compiling with --enable-tsan (ocaml/ocaml#12781#pullrequestreview-1810823086)
  - Mentoring: Meeting with Hari to discuss the false positive and possible fixes
  - Mentoring: Helped Hari improve the fix for the two data races he was working on.

- Misc (No KR)
  - @OlivierNicole (0.5 days)
  - Q1 Planning meeting
  - 1-on-1 with @jmid
  - Added Xavier Leroy's course at "Collège de France" to the Tech Talks Calendar.

# Next Week

- I will watch the PRs submitted by @Johan511 to make sure things get wrapped up nicely after the end of his internship.
- I will follow up on the experiments regarding effects performance in JSOO.
- I will work on the PRs I have committed to review.
