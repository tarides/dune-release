We need a basic opam project skeleton

    $ cat > CHANGES.md << EOF \
    > ## 0.1.0\
    > \
    > - Some other feature\
    > \
    > ## 0.0.0\
    > \
    > - Some feature\
    > EOF
    $ touch whatever.opam
    $ cat > dune-project << EOF \
    > (lang dune 2.4)\
    > (name whatever)\
    > EOF

We need to set up a git project for dune-release to work properly

    $ git init > /dev/null
    $ git add CHANGES.md whatever.opam dune-project
    $ git commit -m "Initial commit" > /dev/null

Let's make `dune-release` run a `git`-command that's doomed to fail. After the customized error line, the error log should contain 
- the exit code/signal,
- the external command that has failed,
- the error message the external command has posted on its stderr.

    $ dune-release tag --commit=1
    [-] Extracting tag from first entry in CHANGES.md
    [-] Using tag "0.1.0"
    dune-release: [ERROR] Due to invalid commit-ish `1`:
                          Exit code 128 from command
                            `git --git-dir .git rev-parse --verify
                          1^{commit}`:
                          fatal: Needed a single revision
    
    [3]
