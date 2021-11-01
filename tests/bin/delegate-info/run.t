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

We need to set up a git project for dune-release to work properly

  $ git init 2> /dev/null > /dev/null
  $ git config user.name "dune-release-test"
  $ git config user.email "pseudo@pseudo.invalid"
  $ git add CHANGES.md whatever.opam dune-project
  $ git commit -m "Initial commit" > /dev/null
  $ dune-release tag -y > /dev/null

Dune-release delegate-info tarball should print the path to the tarball:

  $ dune-release delegate-info tarball
  _build/whatever-0.1.0.tbz

Dune-release delegate-info docdir should print the path to the docdir:

  $ dune-release delegate-info docdir
  _build/default/_doc/_html

Dune-release delegate-info publication-message should print the publication-message:

  $ dune-release delegate-info publication-message
  CHANGES:
  
  - Some other feature
  

