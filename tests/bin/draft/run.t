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
  > description: "whatever"
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
  $ git add CHANGES.md whatever.opam dune-project README LICENSE .gitignore
  $ git commit -m "Initial commit" > /dev/null
  $ dune-release tag -y > /dev/null

We do the whole `dune-release` process but create a draft release on GitHub.

(1) `distrib` as normal

  $ dune-release distrib --dry-run > /dev/null

(2) `publish` when asking for the release to be created as a draft should
create a draft release and submit it as such to GitHub. It should also write a
`draft_release` file for `undraft`.

  $ dune-release publish --dry-run --yes --draft | grep draft
  [-] Creating draft release 0.1.0 on https://github.com/foo/whatever.git via github's API
       {"tag_name":"0.1.0","name":"0.1.0","body":"CHANGES:\n\n- Some other feature\n","draft":true}
  [+] Successfully created draft release with id 1
  -: write _build/whatever-0.1.0.draft_release
