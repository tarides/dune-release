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
  > run.t*
  > EOF

We need to set up a git project for dune-release to work properly

  $ git init > /dev/null
  $ git add CHANGES.md whatever.opam dune-project .gitignore
  $ git commit -m "Initial commit" > /dev/null
  $ dune-release tag -y
  [-] Extracting tag from first entry in CHANGES.md
  [-] Using tag "0.1.0"
  [+] Tagged HEAD with version 0.1.0

Generating the tarball with --include-submodules should call git submodule update --init from within
the tarball build dir:

  $ dune-release distrib --skip-lint --skip-build --skip-test --include-submodule --dry-run | ../sanitize.sh
  [-] Building source archive
  => rmdir _build/whatever-0.1.0.build
  -: exec: git --git-dir .git rev-parse --verify 0.1.0
  => exec: git --git-dir .git show -s --format=%ct 0.1.0^0
  => exec: git --git-dir .git clone --local .git _build/whatever-0.1.0.build
  => exec:
       git --git-dir _build/whatever-0.1.0.build/.git --work-tree   _build/whatever-0.1.0.build/ checkout --quiet -b dune-release-dist-0.1.0   0.1.0
  => chdir _build/whatever-0.1.0.build
     [in _build/whatever-0.1.0.build]
  -: exec: git --git-dir .git submodule update --init
  => chdir _build/whatever-0.1.0.build
  -: exec: dune subst
  -: write whatever.opam
  => exec: bzip2
  -: rmdir _build/whatever-0.1.0.build
  [+] Wrote archive _build/whatever-0.1.0.tbz
  => chdir _build/
     [in _build]
  => exec: tar -xjf whatever-0.1.0.tbz
  -: rmdir _build/whatever-0.1.0
  
  [+] Distribution for whatever 0.1.0
  [+] Commit $COMMIT
  [+] Archive _build/whatever-0.1.0.tbz
