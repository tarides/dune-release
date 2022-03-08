We need a basic opam project skeleton with an empty doc field

  $ cat > CHANGES.md << EOF
  > ## 0.1.0
  > 
  >  - Change A
  >  - Change B
  > 
  > ## 0.0.0
  > 
  > - Some feature
  > EOF
  $ cat > whatever.opam << EOF
  > opam-version: "2.0"
  > homepage: "https://github.com/foo/whatever"
  > dev-repo: "git+https://github.com/foo/whatever.git"
  > synopsis: "whatever"
  > EOF
  $ cat > whatever-lib.opam << EOF
  > opam-version: "2.0"
  > homepage: "https://github.com/foo/whatever"
  > dev-repo: "git+https://github.com/foo/whatever.git"
  > synopsis: "whatever-lib"
  > doc: ""
  > EOF
  $ touch README
  $ touch LICENSE
  $ cat > dune-project << EOF
  > (lang dune 2.4)
  > (name whatever)
  > EOF

We need to set up a git project for dune-release to work properly

  $ git init > /dev/null 2>&1
  $ git config user.name "dune-release-test"
  $ git config user.email "pseudo@pseudo.invalid"
  $ git config remote.origin.url git+https://github.com/foo/whatever.git
  $ git add CHANGES.md whatever.opam whatever-lib.opam dune-project README LICENSE
  $ git commit -m "Initial commit" > /dev/null
  $ dune-release tag -y > /dev/null

Trying to publish the documentation explicitly should fail:

  $ dune-release publish doc -y --dry-run > /dev/null
  dune-release: [ERROR] directory contents _build/whatever-0.1.0: No such file or directory
  [3]

By default it should skip the documentation generation:

  $ dune-release publish -y --dry-run | grep Skipping
  [-] Skipping documentation publication for package whatever: no doc field in whatever.opam
