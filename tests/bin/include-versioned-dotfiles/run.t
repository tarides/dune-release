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
    > .formatted\
    > dune\
    > .mdx\
    > run.t\
    > EOF

We also need a dotfile that we will properly version

  $ echo "hello" > .somedotfile

We need to set up a git project for dune-release to work properly

    $ git init 2> /dev/null > /dev/null
    $ git config user.name "dune-release-test"
    $ git config user.email "pseudo@pseudo.invalid"
    $ git add CHANGES.md whatever.opam dune-project .somedotfile .gitignore
    $ git commit -m "Initial commit" > /dev/null
    $ dune-release tag -y
    [-] Extracting tag from first entry in CHANGES.md
    [-] Using tag "0.1.0"
    [+] Tagged HEAD with version 0.1.0

The generated tarball should contain the dotfile

    $ dune-release distrib --skip-lint --skip-build --skip-test | determinize
    [-] Building source archive
    [+] Wrote archive _build/whatever-0.1.0.tbz
    
    [+] Distribution for whatever 0.1.0
    [+] Commit ...
    [+] Archive _build/whatever-0.1.0.tbz
    $ tar -xjf _build/whatever-0.1.0.tbz
    $ cat whatever-0.1.0/.somedotfile
    hello
