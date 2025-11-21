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
  $ touch whatever.opam
  $ cat > dune-project << EOF
  > (lang dune 2.4)
  > (name whatever)
  > EOF
  $ cat > .gitignore << EOF
  > _build
  > run.t
  > EOF

We need to set up a git project for dune-release to work properly

  $ git init > /dev/null 2>&1
  $ git config user.name "dune-release-test"
  $ git config user.email "pseudo@pseudo.invalid"
  $ git add CHANGES.md whatever.opam dune-project .gitignore
  $ git commit -m "Initial commit" > /dev/null
  $ dune-release tag -y > /dev/null

Generating the tarball with `--include-submodules` should call `git submodule
update --init` from within the tarball build dir:

  $ dune-release distrib --skip-lint --skip-build --skip-tests --include-submodules --dry-run | grep -- "--init"
  -: exec: git --git-dir .git submodule update --init
