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
  > EOF
  $ cat > dune-project << EOF
  > (lang dune 2.4)
  > (name whatever)
  > EOF

We need to set up a git project for dune-release to work properly

  $ git init 2> /dev/null > /dev/null
  $ git config user.name "dune-release-test"
  $ git config user.email "pseudo@pseudo.invalid"
  $ git add CHANGES.md whatever.opam dune-project
  $ git commit -m "Initial commit" > /dev/null

We also need a dummy distrib file to keep the test simple:

  $ mkdir _build
  $ touch _build/whatever-0.1.0.tbz

And a url file as if we just successfully ran dune-release publish distrib:

  $ echo "https://some.fake.url/mytarball.tbz" > _build/whatever-0.1.0.url

Running the following should use the --dist-uri url even if the .url file is present:

  $ dune-release opam pkg \
  > --dist-uri "https://my.custom.url/mytarball.tbz" \
  > --pkg-version 0.1.0 \
  > > /dev/null 2>&1
  $ cat _build/whatever.0.1.0/opam | grep "mytarball.tbz"
    src: "https://my.custom.url/mytarball.tbz"
