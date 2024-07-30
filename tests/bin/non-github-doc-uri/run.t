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
  $ touch README
  $ touch LICENSE
  $ cat > dune-project << EOF
  > (lang dune 2.4)
  > (name whatever)
  > EOF

Here we want the opam file doc not to point to github

  $ cat > whatever.opam << EOF
  > opam-version: "2.0"
  > homepage: "https://whatever.io"
  > dev-repo: "git+https://whatever.io/dev/whatever.git"
  > doc: "https://whatever.io/doc/main.html"
  > synopsis: "whatever"
  > EOF

We need to set up a git project for dune-release to work properly

  $ cat > .gitignore << EOF
  > /dune
  > run.t
  > EOF
  $ git init > /dev/null 2>&1
  $ git config user.name "dune-release-test"
  $ git config user.email "pseudo@pseudo.invalid"
  $ git add CHANGES.md whatever.opam dune-project README LICENSE .gitignore
  $ git commit -m "Initial commit" > /dev/null
  $ dune-release tag -y > /dev/null

When trying to publish the documentation, it should fail as it cannot find
a github URI to publish the documentation to.

(1) distrib

  $ dune-release distrib --dry-run 2>&1 | grep -E "FAIL|ERROR"
  [FAIL] opam fields homepage and dev-repo can be parsed by dune-release
  dune-release: [ERROR] Github development repository URL could not be inferred
  [FAIL] opam field doc cannot be parsed by dune-release
  [FAIL] lint of _build/whatever-0.1.0 and package whatever failure: 2 errors.

(2) publish doc

  $ dune-release publish doc --dry-run > /dev/null
  dune-release: [ERROR] Could not derive publication directory $PATH from opam doc field value "https://whatever.io/doc/main.html"; expected the pattern $SCHEME://$USER.github.io/$REPO/$PATH
  [3]
