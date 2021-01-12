We need a basic opam project skeleton

    $ cat > CHANGES.md << EOF \
    > ## 0.1.0\
    > \
    > - Some other feature\
    > \
    > ## 0.0.0\
    > \
    > - Some feature\
    > EOF
    $ touch whatever.opam
    $ cat > dune-project << EOF \
    > (lang dune 2.4)\
    > (name whatever)\
    > EOF
    $ cat > .gitignore << EOF \
    > _build\
    > run.t*\
    > EOF

We need to set up a git project for dune-release to work properly

    $ git init 2> /dev/null > /dev/null
    $ git config user.name "dune-release-test"
    $ git config user.email "pseudo@pseudo.invalid"
    $ git add CHANGES.md whatever.opam dune-project .gitignore
    $ git commit -m "Initial commit" > /dev/null
    $ dune-release tag -y
    [-] Extracting tag from first entry in CHANGES.md
    [-] Using tag "0.1.0"
    [+] Tagged HEAD with version 0.1.0

Generating the tarball with --include-submodules should call git submodule update --init from within
the tarball build dir:

    $ dune-release distrib --skip-lint --skip-build --skip-test --include-submodule --dry-run
    ...
    => chdir _build/whatever-0.1.0.build
       [in _build/whatever-0.1.0.build]
    -: exec: git --git-dir .git submodule update --init
    ...
    [+] Wrote archive _build/whatever-0.1.0.tbz
    ...
    [+] Archive _build/whatever-0.1.0.tbz
