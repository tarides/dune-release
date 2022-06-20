Set up a project with two packaged libraries, no name in `dune-project`. This
goes with the fix for #320, where:

- one sets a name in `dune-project` but does not commit it
- `dune-release distrib` ignores this name and fails, complaining that you
should set a name.

  $ mkdir liba libb
  $ cat > CHANGES.md << EOF
  > ## 0.42.0
  > 
  > - Some other feature
  > 
  > EOF
  $ echo "(library (public_name liba))" > liba/dune
  $ echo "(library (public_name libb))" > libb/dune
  $ cat > liba.opam << EOF
  > opam-version: "2.0"
  > EOF
  $ cp liba.opam libb.opam
  $ touch README LICENSE
  $ echo "(lang dune 2.7)" > dune-project
  $ cat > .gitignore << EOF
  > _build
  > .bin
  > /dune
  > run.t
  > EOF
  $ git init 2> /dev/null . > /dev/null
  $ git config user.name "dune-release-test"
  $ git config user.email "pseudo@pseudo.invalid"
  $ git add liba/* libb*/ CHANGES.md README LICENSE *.opam dune-project .gitignore
  $ git commit -m 'Commit.' > /dev/null

Try `dune-release distrib` with no project name, it should fail since it does
not know how to call the project.

  $ dune-release distrib --skip-lint > /dev/null
  dune-release: [ERROR] cannot determine distribution name automatically: add (name <name>) to dune-project
  [1]

dune-release distrib --dry-run with no project name should fail as well.

  $ dune-release distrib --skip-lint --dry-run > /dev/null
  dune-release: [ERROR] cannot determine distribution name automatically: add (name <name>) to dune-project
  [1]

Add an uncommitted name to dune-project. (Because of a dune limitation
this name must be one the .opam file names.)

  $ echo "(name liba)" >> dune-project

Run dune-release distrib with the uncommitted name in dune-project.

  $ dune-release tag -y > /dev/null
  $ dune-release distrib --skip-lint > /dev/null
  dune-release: [WARNING] The repo is dirty. Uncommitted changes to files
                          (including dune-project) will not be included in the
                          distribution archive.
  Error: The project name is not defined, please add a (name <name>) field to
  your dune-project file.
  dune-release: [ERROR] run ['dune' 'subst']: exited with 1
  [3]

Commit the change in dune-project and run distrib.

  $ git add dune-project && git commit -m 'add name' > /dev/null
  $ dune-release distrib --skip-lint | make_dune_release_deterministic
  [-] Building source archive
  [+] Wrote archive _build/liba-0.42.0-1-<deterministic>.tbz
  
  [-] Building package in _build/liba-0.42.0-1-<deterministic>
  [ OK ] package(s) build
  
  [-] Running package tests in _build/liba-0.42.0-1-<deterministic>
  [ OK ] package(s) pass the tests
  
  [+] Distribution for liba 0.42.0-1-<deterministic>
  [+] Commit <deterministic>
  [+] Archive _build/liba-0.42.0-1-<deterministic>.tbz
