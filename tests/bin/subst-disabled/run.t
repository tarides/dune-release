Set up a project that disables `dune subst`, as projects whose version
comes from elsewhere do (#496).

  $ mkdir foo
  $ cat > CHANGES.md << EOF
  > ## 0.1.0
  > 
  > - Some feature
  > 
  > EOF
  $ cat > dune-project << EOF
  > (lang dune 3.0)
  > (name foo)
  > (subst disabled)
  > EOF
  $ echo "(library (public_name foo))" > foo/dune
  $ cat > foo.opam << EOF
  > opam-version: "2.0"
  > EOF
  $ touch README LICENSE
  $ cat > .gitignore << EOF
  > _build
  > .bin
  > /dune
  > run.t
  > EOF
  $ git init 2> /dev/null . > /dev/null
  $ git config user.name "dune-release-test"
  $ git config user.email "pseudo@pseudo.invalid"
  $ git add CHANGES.md README LICENSE foo foo.opam dune-project .gitignore
  $ git commit -m 'Commit.' > /dev/null
  $ git tag -a 0.1.0 -m 'Release 0.1.0'

`dune-release distrib` skips `dune subst` instead of failing on it.

  $ dune-release distrib --skip-lint --skip-build --skip-tests | make_dune_release_deterministic
  [-] Building source archive
  [-] Skipping dune subst, disabled in dune-project
  [+] Wrote archive _build/foo-0.1.0.tbz
  
  [+] Distribution for foo 0.1.0
  [+] Commit <deterministic>
  [+] Archive _build/foo-0.1.0.tbz
