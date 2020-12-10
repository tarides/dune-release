Set up a project with two packaged libraries, no name in dune-project.

    $ mkdir liba libb
    $ cat > CHANGES.md << EOF \
    > ## 0.42.0\
    > \
    > - Some other feature\
    > \
    > EOF
    $ echo "let f x = x" > liba/main.ml
    $ echo "(library (public_name liba))" > liba/dune
    $ echo "let f x = x" > libb/main.ml
    $ echo "(library (public_name libb))" > libb/dune
    $ cat > liba.opam << EOF \
    > opam-version: "2.0" \
    > description: "Description"\
    > synopsis: "Synopsis"\
    > maintainer: "Maintainer"\
    > authors: "Authors"\
    > homepage: "homepage"\
    > dev-repo: "git://dev-repo"\
    > bug-reports: "bug-reports"\
    > EOF
    $ cp liba.opam libb.opam
    $ touch README LICENSE
    $ echo "(lang dune 2.7)" > dune-project
    $ git init . > /dev/null
    $ git add liba/* libb*/ CHANGES.md README LICENSE *.opam dune-project
    $ git status
    $ git commit -m 'Commit.' > /dev/null

Try dune-release with no project name.

    $ dune-release distrib
    [-] Building source archive
    dune-release: [WARNING] The repo is dirty. The distribution archive may be
                            inconsistent. Uncommitted changes to files (including
                            dune-project) will be ignored.
    dune-release: [ERROR] cannot determine name automatically: use `-p <name>`
    [1]

<!-- This does not work at the moment. --name is not taken into -->
<!-- account by the dune subst called by dune-release distrib -->
<!-- Run with --name. -->
<!--     $ dune-release distrib --name toto -->

Add an uncommitted name to dune-project. (Because of a dune limitation
this name must be one the .opam file names.)

    $ echo "(name liba)" >> dune-project

Run dune-release distrib with the uncomitted name in dune-project.

    $ dune-release distrib
    [-] Building source archive
    dune-release: [WARNING] The repo is dirty. The distribution archive may be
                            inconsistent. Uncommitted changes to files (including
                            dune-project) will be ignored.
    Error: The project name is not defined, please add a (name <name>) field to
    your dune-project file.
    dune-release: [ERROR] run ['dune' 'subst']: exited with 1
    [3]

Commit the change in dune-project and run distrib.

    $ git add dune-project && git commit -m 'add name' > /dev/null
    $ dune-release distrib
    [-] Building source archive
    dune-release: [WARNING] The repo is dirty. The distribution archive may be
                            inconsistent. Uncommitted changes to files (including
                            dune-project) will be ignored.
    [+] Wrote archive _build/liba-a23cbd9.tbz
    
    [-] Linting distrib in _build/liba-a23cbd9
    [ OK ] File README is present.
    [ OK ] File LICENSE is present.
    [ OK ] File CHANGES is present.
    [ OK ] File opam is present.
    [ OK ] lint opam file libb.opam.
    [ OK ] opam field description is present
    [ OK ] opam fields homepage and dev-repo can be parsed by dune-release
    [ OK ] Skipping doc field linting, no doc field found
    [ OK ] lint _build/liba-a23cbd9 success
    [ OK ] File README is present.
    [ OK ] File LICENSE is present.
    [ OK ] File CHANGES is present.
    [ OK ] File opam is present.
    [ OK ] lint opam file liba.opam.
    [ OK ] opam field description is present
    [ OK ] opam fields homepage and dev-repo can be parsed by dune-release
    [ OK ] Skipping doc field linting, no doc field found
    [ OK ] lint _build/liba-a23cbd9 success
    
    [-] Building package in _build/liba-a23cbd9
    [ OK ] package builds
    
    [-] Running package tests in _build/liba-a23cbd9
    [ OK ] package tests
    
    [+] Distribution for liba a23cbd9
    [+] Commit a23cbd9b2d83ce2f08e64e7c325659ce219d6f3e
    [+] Archive _build/liba-a23cbd9.tbz
