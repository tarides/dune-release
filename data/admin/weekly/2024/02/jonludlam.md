jonludlam week 2: 2024/01/08 -- 2024/01/14

# Projects

- General odoc maintenance (#59)
- Odoc Performance Scales to Jane Street Codebase (#1096)
- Defining Scope and referencing for documentation pages (#1101)
- Odoc has a global navigation sidebar containing API and standalone pages (#76)

# Last Week

- Investigation of docs CI (No KR)
  - @jonludlam (2 days)
  - Getting to grips with how the docs CI pipeline works these days. Set up
    a build worker and cluster bits and pieces. Rsync is abysmal and can't
    be used, so set up an ubuntu build worker with zfs. This caused problems
    so set up btrfs instead, this worked much better.
  - Investigated improvements to the prep phase, installing packages one-by-one
    following topological sort of the dependencies. This was slow due to opam,
    so tried incrememntally building opam repository containing only the
    required packages. This was much faster.

- Odoc Performance Scales to Jane Street Codebase (#1096)
  - @jonludlam (1 day)
  - Continued work on the `original-path` branch

- Other (No KR)
  - @jonludlam (2 days)
  - Q1 meetings of various sorts, both compiler-backend and documentation

# Activity (move these items to last week)


