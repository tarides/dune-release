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
    $ git init 2> /dev/null > /dev/null
    $ git config user.name "dune-release-test"
    $ git config user.email "pseudo@pseudo.invalid"
    $ git add CHANGES.md whatever.opam dune-project README LICENSE .gitignore
    $ git commit -m "Initial commit" > /dev/null
    $ dune-release tag -y
    [-] Extracting tag from first entry in CHANGES.md
    [-] Using tag "3.3.4_TILDE_4.10preview1"
    [+] Tagged HEAD with version 3.3.4_TILDE_4.10preview1

We do the whole dune-release process

(1) distrib

    $ dune-release distrib --dry-run | grep preview1
    => rmdir _build/whatever-3.3.4~4.10preview1.build
    -: exec: git --git-dir .git rev-parse --verify 3.3.4_TILDE_4.10preview1
    => exec: git --git-dir .git show -s --format=%ct 3.3.4_TILDE_4.10preview1^0
         git --git-dir .git clone --local .git   _build/whatever-3.3.4~4.10preview1.build
         git --git-dir _build/whatever-3.3.4~4.10preview1.build/.git --work-tree   _build/whatever-3.3.4~4.10preview1.build/ checkout --quiet -b   dune-release-dist-3.3.4_TILDE_4.10preview1 3.3.4_TILDE_4.10preview1
    => chdir _build/whatever-3.3.4~4.10preview1.build
       [in _build/whatever-3.3.4~4.10preview1.build]
    -: rmdir _build/whatever-3.3.4~4.10preview1.build
    [+] Wrote archive _build/whatever-3.3.4~4.10preview1.tbz
    => exec: tar -xjf whatever-3.3.4~4.10preview1.tbz
    [-] Linting distrib in _build/whatever-3.3.4~4.10preview1
    => chdir _build/whatever-3.3.4~4.10preview1
       [in _build/whatever-3.3.4~4.10preview1]
    [ OK ] lint _build/whatever-3.3.4~4.10preview1 success
    [-] Building package in _build/whatever-3.3.4~4.10preview1
    => chdir _build/whatever-3.3.4~4.10preview1
    [-] Running package tests in _build/whatever-3.3.4~4.10preview1
    => chdir _build/whatever-3.3.4~4.10preview1
    -: rmdir _build/whatever-3.3.4~4.10preview1
    [+] Distribution for whatever 3.3.4~4.10preview1
    [+] Archive _build/whatever-3.3.4~4.10preview1.tbz

(2) publish distrib

    $ dune-release publish distrib --dry-run --yes | grep preview1
    => must exists _build/whatever-3.3.4~4.10preview1.tbz
    -: exec: git --git-dir .git rev-parse --verify 3.3.4_TILDE_4.10preview1
    -: exec: git --git-dir .git rev-parse --verify 3.3.4_TILDE_4.10preview1
         git --git-dir .git ls-remote --quiet --tags https://github.com/user/repo.git   3.3.4_TILDE_4.10preview1
    [-] Pushing tag 3.3.4_TILDE_4.10preview1 to git@github.com:user/repo.git
         git --git-dir .git push --force git@github.com:user/repo.git   3.3.4_TILDE_4.10preview1
    [-] Creating release 3.3.4~4.10preview1 on https://github.com/user/repo.git via github's API
         {"tag_name":"3.3.4_TILDE_4.10preview1","name":"3.3.4~4.10preview1","body":"CHANGES:\n\n- Some other feature\n"}
    [-] Uploading _build/whatever-3.3.4~4.10preview1.tbz as a release asset for 3.3.4~4.10preview1 via github's API
         @_build/whatever-3.3.4~4.10preview1.tbz
    -: write _build/whatever-3.3.4~4.10preview1.url

Check the changelog

    $ cat _build/whatever-3.3.4~4.10preview1/CHANGES.md
    ## 3.3.4~4.10preview1
    
    - Some other feature
    
    ## 0.0.0
    
    - Some feature
