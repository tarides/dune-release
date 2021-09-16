We need a basic opam project skeleton

    $ cat > CHANGES.md << EOF \
    > ## whatever 0.1.0\
    > \
    > - Some other feature\
    > \
    > ## whatever 0.0.0\
    > \
    > - Some feature\
    > EOF
    $ cat > whatever.opam << EOF \
    > opam-version: "2.0"\
    > homepage: "https://github.com/foo/whatever"\
    > dev-repo: "git+https://github.com/foo/whatever.git"\
    > description: "whatever"\
    > EOF
    $ touch README.md LICENSE
    $ cat > dune-project << EOF \
    > (lang dune 2.4)\
    > (name whatever)\
    > EOF
    $ cat > .gitignore << EOF \
    > _build/\
    > .mdx\
    > run.t\
    > EOF

We need to set up a git project with two commits to test trying to tag different commits with the same tag name.

    $ git init 2> /dev/null > /dev/null
    $ git add whatever.opam dune-project .gitignore CHANGES.md README.md LICENSE
    $ git commit -m "" --allow-empty-message --quiet

Creating a `git tag` manually since the project might be using this workflow

    $ git tag -a 23.0 -m "Release 23.0"
    $ dune-release distrib --dry-run | grep -vE "Commit [a-f0-9]{40}"
    [-] Building source archive
    => rmdir _build/whatever-23.0.build
    -: exec: git --git-dir .git rev-parse --verify refs/tags/23.0
    => exec: git --git-dir .git show -s --format=%ct 23.0^0
    => exec: git --git-dir .git clone --local .git _build/whatever-23.0.build
    => exec:
         git --git-dir _build/whatever-23.0.build/.git --work-tree   _build/whatever-23.0.build/ checkout --quiet -b dune-release-dist-23.0 23.0
    => chdir _build/whatever-23.0.build
       [in _build/whatever-23.0.build]
    -: exec: dune subst
    -: write whatever.opam
    => exec: bzip2
    -: rmdir _build/whatever-23.0.build
    [+] Wrote archive _build/whatever-23.0.tbz
    => chdir _build/
       [in _build]
    => exec: tar -xjf whatever-23.0.tbz
    
    [-] Performing lint for package whatever in _build/whatever-23.0
    => chdir _build/whatever-23.0
       [in _build/whatever-23.0]
    => exists ./README.md
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
    [ OK ] opam fields homepage and dev-repo can be parsed by dune-release
    [ OK ] Skipping doc field linting, no doc field found
    [ OK ] lint of _build/whatever-23.0 and package whatever success
    
    [-] Building package in _build/whatever-23.0
    => chdir _build/whatever-23.0
    -: exec: dune build -p whatever
    [ OK ] package(s) build
    
    [-] Running package tests in _build/whatever-23.0
    => chdir _build/whatever-23.0
    -: exec: dune runtest -p whatever
    [ OK ] package(s) pass the tests
    -: rmdir _build/whatever-23.0
    
    [+] Distribution for whatever 23.0
    [+] Archive _build/whatever-23.0.tbz

Also, while not the preferred way, unannotated tags should be possible as well

    $ git commit --allow-empty -m '' --allow-empty-message --quiet
    $ git tag 42.0
    $ dune-release distrib --dry-run | grep -vE "Commit [a-f0-9]{40}"
    [-] Building source archive
    => rmdir _build/whatever-42.0.build
    -: exec: git --git-dir .git rev-parse --verify refs/tags/42.0
    => exec: git --git-dir .git show -s --format=%ct 42.0^0
    => exec: git --git-dir .git clone --local .git _build/whatever-42.0.build
    => exec:
         git --git-dir _build/whatever-42.0.build/.git --work-tree   _build/whatever-42.0.build/ checkout --quiet -b dune-release-dist-42.0 42.0
    => chdir _build/whatever-42.0.build
       [in _build/whatever-42.0.build]
    -: exec: dune subst
    -: write whatever.opam
    => exec: bzip2
    -: rmdir _build/whatever-42.0.build
    [+] Wrote archive _build/whatever-42.0.tbz
    => chdir _build/
       [in _build]
    => exec: tar -xjf whatever-42.0.tbz
    
    [-] Performing lint for package whatever in _build/whatever-42.0
    => chdir _build/whatever-42.0
       [in _build/whatever-42.0]
    => exists ./README.md
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
    [ OK ] opam fields homepage and dev-repo can be parsed by dune-release
    [ OK ] Skipping doc field linting, no doc field found
    [ OK ] lint of _build/whatever-42.0 and package whatever success
    
    [-] Building package in _build/whatever-42.0
    => chdir _build/whatever-42.0
    -: exec: dune build -p whatever
    [ OK ] package(s) build
    
    [-] Running package tests in _build/whatever-42.0
    => chdir _build/whatever-42.0
    -: exec: dune runtest -p whatever
    [ OK ] package(s) pass the tests
    -: rmdir _build/whatever-42.0
    
    [+] Distribution for whatever 42.0
    [+] Archive _build/whatever-42.0.tbz
