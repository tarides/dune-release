We need a basic opam project skeleton

    $ cat > CHANGES.md << EOF \
    > ## 3.3.4~4.10preview1\
    > \
    > - Some other feature\
    > \
    > ## 0.0.0\
    > \
    > - Some feature\
    > EOF
    $ cat > whatever.opam << EOF \
    > opam-version: "2.0"\
    > homepage: "https://github.com/user/repo"\
    > dev-repo: "git+https://github.com/user/repo.git"\
    > description: "whatever"\
    > EOF
    $ touch README
    $ touch LICENSE
    $ cat > dune-project << EOF \
    > (lang dune 2.4)\
    > (name whatever)\
    > EOF

We need to set up a git project for dune-release to work properly

    $ cat > .gitignore << EOF \
    > _build\
    > .formatted\
    > .mdx\
    > /dune\
    > run.t\
    > EOF
    $ git init > /dev/null
    $ git add CHANGES.md whatever.opam dune-project README LICENSE .gitignore
    $ git commit -m "Initial commit" > /dev/null
    $ dune-release tag -y
    [-] Extracting tag from first entry in CHANGES.md
    [-] Using tag "3.3.4_TILDE_4.10preview1"
    [+] Tagged HEAD with version 3.3.4_TILDE_4.10preview1

We do the whole dune-release process

(1) distrib

    $ dune-release distrib --dry-run
    [-] Building source archive
    => rmdir _build/whatever-3.3.4~4.10preview1.build
    -: exec: git --git-dir .git rev-parse --verify 3.3.4_TILDE_4.10preview1
    => exec: git --git-dir .git show -s --format=%ct 3.3.4_TILDE_4.10preview1^0
    => exec:
         git --git-dir .git clone --local .git   _build/whatever-3.3.4~4.10preview1.build
    => exec:
         git --git-dir _build/whatever-3.3.4~4.10preview1.build/.git --work-tree   _build/whatever-3.3.4~4.10preview1.build/ checkout --quiet -b   dune-release-dist-3.3.4_TILDE_4.10preview1 3.3.4_TILDE_4.10preview1
    => chdir _build/whatever-3.3.4~4.10preview1.build
       [in _build/whatever-3.3.4~4.10preview1.build]
    -: exec: dune subst
    -: write whatever.opam
    => exec: bzip2
    -: rmdir _build/whatever-3.3.4~4.10preview1.build
    [+] Wrote archive _build/whatever-3.3.4~4.10preview1.tbz
    => chdir _build/
       [in _build]
    => exec: tar -xjf whatever-3.3.4~4.10preview1.tbz
    
    [-] Linting distrib in _build/whatever-3.3.4~4.10preview1
    => chdir _build/whatever-3.3.4~4.10preview1
       [in _build/whatever-3.3.4~4.10preview1]
    => exists ./README
    [ OK ] File README is present.
    => exists ./LICENSE
    [ OK ] File LICENSE is present.
    => exists ./CHANGES.md
    [ OK ] File CHANGES is present.
    => exists whatever.opam
    [ OK ] File opam is present.
    -: exec: opam lint -s whatever.opam
    [ OK ] lint opam file whatever.opam.
    [ OK ] opam field description is present
    [ OK ] opam fields homepage and dev-repo can be parsed by dune-release
    [ OK ] Skipping doc field linting, no doc field found
    [ OK ] lint _build/whatever-3.3.4~4.10preview1 success
    
    [-] Building package in _build/whatever-3.3.4~4.10preview1
    => chdir _build/whatever-3.3.4~4.10preview1
    -: exec: dune build -p whatever
    [ OK ] package builds
    
    [-] Running package tests in _build/whatever-3.3.4~4.10preview1
    => chdir _build/whatever-3.3.4~4.10preview1
    -: exec: dune runtest -p whatever
    [ OK ] package tests
    -: rmdir _build/whatever-3.3.4~4.10preview1
    
    [+] Distribution for whatever 3.3.4~4.10preview1
    [+] Commit ...
    [+] Archive _build/whatever-3.3.4~4.10preview1.tbz

(2) publish distrib

    $ yes | dune-release publish distrib --dry-run
    [-] Publishing distribution
    => must exists _build/whatever-3.3.4~4.10preview1.tbz
    [-] Publishing to github
    -: exec: git --git-dir .git rev-parse --verify 3.3.4_TILDE_4.10preview1
    -: exec: git --git-dir .git rev-parse --verify 3.3.4_TILDE_4.10preview1
    -: exec:
         git --git-dir .git ls-remote --quiet --tags https://github.com/user/repo.git   3.3.4_TILDE_4.10preview1
    [?] Push tag 3.3.4_TILDE_4.10preview1 to git@github.com:user/repo.git? [Y/n]
    [-] Pushing tag 3.3.4_TILDE_4.10preview1 to git@github.com:user/repo.git
    -: exec:
         git --git-dir .git push --force git@github.com:user/repo.git   3.3.4_TILDE_4.10preview1
    ...
    [?] Create release 3.3.4~4.10preview1 on https://github.com/user/repo.git? [Y/n]
    [-] Creating release 3.3.4~4.10preview1 on https://github.com/user/repo.git via github's API
    -: exec: curl --user user:${token} --location --silent --show-error --config -
         --dump-header - --data
         {"tag_name":"3.3.4_TILDE_4.10preview1","name":"3.3.4~4.10preview1","body":"CHANGES:\n\n- Some other feature\n"}
    [+] Succesfully created release with id 1
    [?] Upload _build/whatever-3.3.4~4.10preview1.tbz as release asset? [Y/n]
    [-] Uploading _build/whatever-3.3.4~4.10preview1.tbz as a release asset for 3.3.4~4.10preview1 via github's API
    -: exec: curl --user user:${token} --location --silent --show-error --config -
         --dump-header - --header Content-Type:application/x-tar --data-binary
         @_build/whatever-3.3.4~4.10preview1.tbz
    -: write _build/whatever-3.3.4~4.10preview1.url

Check the changelog

    $ cat _build/whatever-3.3.4~4.10preview1/CHANGES.md
    ## 3.3.4~4.10preview1
    
    - Some other feature
    
    ## 0.0.0
    
    - Some feature
