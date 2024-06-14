EmileTrotignon week 2: 2024/01/08 -- 2024/01/14

# Projects

- Odoc has a search bar to search through the documentation (Plat244)
- Odoc has a global navigation sidebar containing API and standalone pages (Plat239)

# Last Week

- Planning meeting (No KR)
    - @EmileTrotignon (0.5 days)
    - Planning meeting for Q1 2024

- Odoc has a global navigation sidebar containing API and standalone pages (Plat239)
    - @EmileTrotignon (0.5 days)
    - I researched design of sidebar. I also wrote ideas for terminology.

- Odoc has a search bar to search through the documentation (Plat244)
    - @EmileTrotignon (4 days)
    - I worked with Sabine on making voodoo compatible with odoc 2.4. Making
      this type was not difficult, but we then the test failed. We found out
      later that Guillaume had made a PR for compatibility with odoc 2.3, which
      was most of the work (voodoo currently supports odoc 2.2). Guillaume
      updated his PR for 2.4, and then I made sure it was compatible with
      ocaml.org (it was with a tiny patch).
    - I also tried to make dune find sherlodoc.js in /share. I found this to be
      too difficult and decided not to install sherlodoc.js, but have a
      subcommand `sherlodoc js` that produces the file anywhere, in the same
      vein as odoc handle its static files. After this was decided I could not
      work on it because I am waiting for patches from Arthur.
