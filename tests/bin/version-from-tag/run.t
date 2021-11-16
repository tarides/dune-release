We need a basic opam project skeleton

  $ cat > CHANGES.md << EOF
  > ## whatever 0.1.0
  > 
  > - Some other feature
  > 
  > ## whatever 0.0.0
  > 
  > - Some feature
  > EOF
  $ cat > whatever.opam << EOF
  > opam-version: "2.0"
  > homepage: "https://github.com/foo/whatever"
  > dev-repo: "git+https://github.com/foo/whatever.git"
  > description: "whatever"
  > EOF
  $ touch README.md LICENSE
  $ cat > dune-project << EOF
  > (lang dune 2.4)
  > (name whatever)
  > EOF
  $ cat > .gitignore << EOF
  > _build/
  > run.t
  > EOF

We need to set up a git project with two commits to test trying to tag different commits with the same tag name.

  $ git init 2> /dev/null > /dev/null
  $ git config user.name "dune-release-test"
  $ git config user.email "pseudo@pseudo.invalid"
  $ git add whatever.opam dune-project .gitignore CHANGES.md README.md LICENSE
  $ git commit -m "Testing" --quiet

Creating a `git tag` manually since the project might be using this workflow

  $ git tag -a 23.0 -m "Release 23.0"
  $ dune-release distrib --dry-run | grep "Archive _build/"
  [+] Archive _build/whatever-23.0.tbz

Also, while not the preferred way, unannotated tags should be possible as well

  $ git commit --allow-empty -m "Testing" --quiet
  $ git tag 42.0
  $ dune-release distrib --dry-run | grep "Archive _build/"
  [+] Archive _build/whatever-42.0.tbz

It should also properly map back tags to releases

  $ git commit --allow-empty -m "Testing" --quiet
  $ git tag -a 1337.0_beta1 -m 'Release 1337~beta1'
  $ dune-release distrib --dry-run | grep "Archive _build/"
  [+] Archive _build/whatever-1337.0~beta1.tbz

Also, specifying the tag manually should work

  $ git commit --allow-empty -m 'Testing' --quiet
  $ dune-release tag -y 9000_alpha3
  [-] Using tag "9000_alpha3"
  [+] Tagged HEAD with version 9000_alpha3
  $ dune-release distrib --dry-run | grep "Archive _build/"
  [+] Archive _build/whatever-9000~alpha3.tbz
