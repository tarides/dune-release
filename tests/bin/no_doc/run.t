We need a basic opam project skeleton with an empty doc field

    $ cat > CHANGES.md << EOF \
    > ## 0.1.0\
    > \
    >  - Change A   \
    >  - Change B\
    > \
    > ## 0.0.0\
    > \
    > - Some feature\
    > EOF
    $ cat > whatever.opam << EOF \
    > opam-version: "2.0"\
    > homepage: "https://github.com/foo/whatever"\
    > dev-repo: "git+https://github.com/foo/whatever.git"\
    > description: "whatever"\
    > EOF
    $ cat > whatever-lib.opam << EOF \
    > opam-version: "2.0"\
    > homepage: "https://github.com/foo/whatever"\
    > dev-repo: "git+https://github.com/foo/whatever.git"\
    > description: "whatever-lib"\
    > doc: ""\
    > EOF
    $ touch README
    $ touch LICENSE
    $ cat > dune-project << EOF \
    > (lang dune 2.4)\
    > (name whatever)\
    > EOF

We need to set up a git project for dune-release to work properly

    $ git init > /dev/null
    $ git add CHANGES.md whatever.opam whatever-lib.opam dune-project README LICENSE
    $ git commit -m "Initial commit" > /dev/null
    $ dune-release tag -y
    [-] Extracting tag from first entry in CHANGES.md
    [-] Using tag "0.1.0"
    [+] Tagged HEAD with version 0.1.0

Trying to publish the documentation explicitly should fail:

    $ dune-release publish doc -y --dry-run
    [-] Publishing documentation
    ...
    dune-release: [ERROR] directory contents _build/whatever-0.1.0: No such file or directory
    [3]

By default it should skip the documentation generation:

    $ dune-release publish -y --dry-run
    [-] Skipping documentation publication for package whatever: no doc field in whatever.opam
    [-] Publishing distribution
    ...
