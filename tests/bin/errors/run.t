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

Let's provoke a one-line error

  $ dune-release delegate-info hi
  dune-release: [ERROR] Unknown variable "hi"
  [3]

Let's provoke a multi-line error

  $ dune-release config hi
  dune-release: [ERROR] Invalid dune-release config invocation. Usage:
    dune-release config
    dune-release config show [KEY]
    dune-release config set KEY VALUE
  [3]

Let's make `dune-release` run a `git`-command that's doomed to fail. After the customized error line, the error log should contain 
- the exit code/signal,
- the external command that has failed,
- the error message the external command has posted on its stderr.

  $ dune-release tag --commit=1
  [-] Extracting tag from first entry in CHANGES.md
  [-] Using tag "0.1.0"
  dune-release: [ERROR] Due to invalid commit-ish `1`:
    Exit code 128 from command 
      `git --git-dir .git rev-parse --verify 1^0`:
    fatal: Needed a single revision
    
  [3]
