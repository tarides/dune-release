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
  > homepage: "https://github.com/foo/whatever"
  > dev-repo: "git+https://github.com/foo/whatever.git"
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
  > /dune
  > run.t
  > EOF
  $ git init > /dev/null 2>&1
  $ git config user.name "dune-release-test"
  $ git config user.email "pseudo@pseudo.invalid"
  $ git config remote.origin.url git+https://github.com/foo/whatever.git
  $ git add CHANGES.md whatever.opam dune-project README LICENSE .gitignore
  $ git commit -m "Initial commit" > /dev/null
  $ dune-release tag -y > /dev/null

We make a dry-run release and check that the opam file is correct:

(1) Creating the distribution archive

  $ dune-release distrib --dry-run > /dev/null

(2) Publishing the distribution

  $ dune-release publish --dry-run --yes > /dev/null

(3) Creating an opam package with a pre-set URL (since we did not upload to GitHub)

  $ echo "https://foo.fr/archive/foo/foo.tbz" > _build/asset-0.1.0.url
  $ dune-release opam pkg
  [-] Creating opam package description for whatever
  [+] Wrote opam package description _build/whatever.0.1.0/opam

(4) Check that the OPAM file contains the right data

  $ cat _build/whatever.0.1.0/opam | sed -e 's/\(x-commit-hash:\) "[0-9a-f]*"/\1 "1abe11ed"/' | sed -n '1h;1!H;${g;s/checksum: \[.*\]/checksum: []/;p;}'
  opam-version: "2.0"
  homepage: "https://github.com/foo/whatever"
  dev-repo: "git+https://github.com/foo/whatever.git"
  synopsis: "whatever"
  url {
    src: "https://foo.fr/archive/foo/foo.tbz"
    checksum: []
  }
  x-commit-hash: "1abe11ed"
