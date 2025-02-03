We need a basic opam project skeleton

  $ cat > CHANGES.md << EOF
  > ## 0.1.0
  > 
  > - Some other feature
  > 
  > ## 0.0.0
  > 
  > - Some feature
  > EOF

  $ touch README
  $ touch LICENSE
  $ cat > dune-project << EOF
  > (lang dune 2.4)
  > (name whatever)
  > EOF

Here we want the opam file not to point to github

  $ cat > whatever.opam << EOF
  > opam-version: "2.0"
  > homepage: "https://whatever.io"
  > dev-repo: "git+https://whatever.io/dev/whatever.git"
  > synopsis: "whatever"
  > EOF

We need to set up a git project for dune-release to work properly

  $ cat > .gitignore << EOF
  > _build
  > /dune
  > run.t
  > EOF
  $ git init 2> /dev/null > /dev/null
  $ git config user.name "dune-release-test"
  $ git config user.email "pseudo@pseudo.invalid"
  $ git add CHANGES.md whatever.opam dune-project README LICENSE .gitignore
  $ git commit -m "Initial commit" > /dev/null
  $ dune-release tag -y
  [-] Extracting tag from first entry in CHANGES.md
  [-] Using tag "0.1.0"
  [+] Tagged HEAD with version 0.1.0

Since the repo is not hosted on github, attempting to publish the distribution
archive should fail as only publishing to github is supported.

(1) distrib

  $ dune-release distrib --dry-run 2>&1 | grep -E "FAIL|ERROR"
  [FAIL] opam fields homepage and dev-repo can be parsed by dune-release
  dune-release: [ERROR] Github development repository URL could not be inferred
  [FAIL] lint of _build/whatever-0.1.0 and package whatever failure: 1 errors.

(2) publish

  $ dune-release publish --dry-run > /dev/null
  dune-release: [ERROR] Github development repository URL could not be inferred from opam files.
  [3]
