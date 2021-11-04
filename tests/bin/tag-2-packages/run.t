Set up a project with two packaged libraries, no name in `dune-project`.

  $ mkdir liba libb
  $ cat > CHANGES.md << EOF
  > ## 0.42.0
  > 
  > - Some other feature
  > 
  > EOF
  $ echo "let f x = x" > liba/main.ml
  $ echo "(library (public_name liba))" > liba/dune
  $ echo "let f x = x" > libb/main.ml
  $ echo "(library (public_name libb))" > libb/dune
  $ touch liba.opam libb.opam
  $ echo "(lang dune 2.7)" > dune-project
  $ git init > /dev/null 2>&1
  $ git config user.name "dune-release-test"
  $ git config user.email "pseudo@pseudo.invalid"
  $ git add liba/* libb*/ CHANGES.md *.opam dune-project
  $ git commit -m 'Commit.' > /dev/null

Expect an error message about the name in `dune-project`.

  $ dune-release tag -y
  dune-release: [ERROR] cannot determine distribution name automatically: add (name <name>) to dune-project
  [1]

Use `(name <name>)` in `dune-project` (not committed).

  $ cat > CHANGES.md << EOF
  > ## 0.44.0
  > 
  > - Some other feature
  > 
  > EOF
  $ git add CHANGES.md
  $ git commit -m '0.44' > /dev/null
  $ echo "(name titi)" >> dune-project

Expect the tagging to work now:

  $ dune-release tag -y
  [-] Extracting tag from first entry in CHANGES.md
  [-] Using tag "0.44.0"
  [+] Tagged HEAD with version 0.44.0
