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
  $ cat > whatever.opam << EOF
  > opam-version: "2.0"
  > homepage: "https://whatever.io"
  > dev-repo: "git+https://whatever.io/dev/whatever.git"
  > synopsis: "whatever"
  > EOF
  $ touch README
  $ touch LICENSE
  $ cat > dune-project << EOF
  > (lang dune 2.4)
  > (name whatever)
  > EOF

We need to set up a git project for dune-release to work properly

  $ cat > .gitignore << EOF
  > _build
  > .formatted
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

We do the whole dune-release process

(1) distrib

  $ dune-release distrib --dry-run 2>&1 | grep -vE "Commit [a-f0-9]{40}"
  [-] Building source archive
  => rmdir _build/whatever-0.1.0.build
  -: exec: git --git-dir .git rev-parse --verify refs/tags/0.1.0
  => exec: git --git-dir .git show -s --format=%ct 0.1.0^0
  => exec: git --git-dir .git clone --local .git _build/whatever-0.1.0.build
  => exec:
       git --git-dir _build/whatever-0.1.0.build/.git --work-tree   _build/whatever-0.1.0.build/ checkout --quiet -b dune-release-dist-0.1.0   0.1.0
  => chdir _build/whatever-0.1.0.build
     [in _build/whatever-0.1.0.build]
  -: exec: dune subst
  -: write whatever.opam
  => exec: bzip2
  -: rmdir _build/whatever-0.1.0.build
  [+] Wrote archive _build/whatever-0.1.0.tbz
  => chdir _build/
     [in _build]
  => exec: tar -xjf whatever-0.1.0.tbz
  
  [-] Performing lint for package whatever in _build/whatever-0.1.0
  => chdir _build/whatever-0.1.0
     [in _build/whatever-0.1.0]
  => exists ./README
  [ OK ] File README is present.
  => exists ./LICENSE
  [ OK ] File LICENSE is present.
  => exists ./CHANGES.md
  [ OK ] File CHANGES is present.
  => exists whatever.opam
  [ OK ] File opam is present.
  -: exec: opam lint -s whatever.opam
  [ OK ] lint opam file whatever.opam.
  [ OK ] opam field synopsis is present
  [FAIL] opam fields homepage and dev-repo can be parsed by dune-release
  dune-release: [ERROR] Github development repository URL could not be
                        inferred.
  [ OK ] Skipping doc field linting, no doc field found
  [FAIL] lint of _build/whatever-0.1.0 and package whatever failure: 1 errors.
  
  [-] Building package in _build/whatever-0.1.0
  => chdir _build/whatever-0.1.0
  -: exec: dune build -p whatever
  [ OK ] package(s) build
  
  [-] Running package tests in _build/whatever-0.1.0
  => chdir _build/whatever-0.1.0
  -: exec: dune runtest -p whatever
  [ OK ] package(s) pass the tests
  
  [+] Distribution for whatever 0.1.0
  [+] Archive _build/whatever-0.1.0.tbz

(2) publish distrib

  $ dune-release publish distrib --dry-run
  [-] Publishing distribution
  => must exists _build/whatever-0.1.0.tbz
  dune-release: [ERROR] whatever-dune-release-delegate: package delegate cannot be found. Try `dune-release help delegate` for more information.
  [3]
