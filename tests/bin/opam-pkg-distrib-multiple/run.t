Set up a project with two opam packages

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
  > dev-repo: "git+https://github.com/user/whatever.git"
  > homepage: "https://github.com/user/whatever"
  > synopsis: "Whatever"
  > EOF
  $ cat > whatever-sub.opam << EOF
  > opam-version: "2.0"
  > dev-repo: "git+https://github.com/user/whatever.git"
  > homepage: "https://github.com/user/whatever"
  > synopsis: "Whatever"
  > EOF
  $ cat > dune-project << EOF
  > (lang dune 2.4)
  > (name whatever)
  > EOF
  $ cat > .gitignore << EOF
  > run.t
  > _build
  > EOF

Set up a git project for dune-release to work properly

  $ git init 2> /dev/null > /dev/null
  $ git add CHANGES.md whatever.opam whatever-sub.opam dune-project .gitignore
  $ git commit -m "Initial commit" > /dev/null

Do the release and create a tarball

  $ dune-release tag -y v0.1.0 > /dev/null
  $ dune-release distrib --dry-run > /dev/null
  [1]

To avoid having to interact with the outside world, we set the URL of the asset
manually

  $ echo "https://some.fake.url/mytarball.tbz" > _build/asset-0.1.0.url

Generating the OPAM files should pick up the right URL for both OPAM files:

  $ dune-release opam pkg > /dev/null
  $ cat _build/whatever.0.1.0/opam | grep 'src:'
    src: "https://some.fake.url/mytarball.tbz"
  $ cat _build/whatever-sub.0.1.0/opam | grep 'src:'
    src: "https://some.fake.url/mytarball.tbz"
