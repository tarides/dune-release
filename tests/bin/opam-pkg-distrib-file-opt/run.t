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
  $ git config remote.origin.url git+https://github.com/foo/whatever.git
  $ git add CHANGES.md whatever.opam dune-project
  $ git commit -m "Initial commit" > /dev/null

We want to use our custom distribution archive instead of the one dune-release would have
generated:

  $ touch our-custom-distrib.tbz

Running the following should not fail if the dune-release generated tarball
(i.e. here _build/whatever-0.1.0.tbz) is not present:

  $ dune-release opam pkg \
  > --dist-file ./our-custom-distrib.tbz \
  > --dist-uri "https://my.custom.url/mytarball.tbz" \
  > --pkg-version 0.1.0
  [-] Creating opam package description for whatever
  [+] Wrote opam package description _build/whatever.0.1.0/opam
  dune-release: [WARNING] The repo is dirty. The opam package may be
                          inconsistent with the distribution.
