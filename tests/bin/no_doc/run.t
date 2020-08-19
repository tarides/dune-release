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

We make a dry-run release

    $ dune-release distrib --dry-run
    [-] Building source archive
    => rmdir _build/whatever-0.1.0.build
    -: exec: git --git-dir .git rev-parse --verify 0.1.0
    => exec: git --git-dir .git show -s --format=%ct 0.1.0^{commit}
    => exec: git --git-dir .git clone --local .git _build/whatever-0.1.0.build
    => exec:
         git --git-dir _build/whatever-0.1.0.build/.git --work-tree   _build/whatever-0.1.0.build/ checkout --quiet -b dune-release-dist-0.1.0   0.1.0
    => chdir _build/whatever-0.1.0.build
       [in _build/whatever-0.1.0.build]
    -: exec: dune subst
    -: write whatever.opam
    -: write whatever-lib.opam
    => exec: bzip2
    -: rmdir _build/whatever-0.1.0.build
    [+] Wrote archive _build/whatever-0.1.0.tbz
    => chdir _build/
       [in _build]
    => exec: tar -xjf whatever-0.1.0.tbz
    
    [-] Linting distrib in _build/whatever-0.1.0
    => chdir _build/whatever-0.1.0
       [in _build/whatever-0.1.0]
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
    [ OK ] lint _build/whatever-0.1.0 success
    => chdir _build/whatever-0.1.0
    => exists ./README
    [ OK ] File README is present.
    => exists ./LICENSE
    [ OK ] File LICENSE is present.
    => exists ./CHANGES.md
    [ OK ] File CHANGES is present.
    => exists whatever-lib.opam
    [ OK ] File opam is present.
    -: exec: opam lint -s whatever-lib.opam
    [ OK ] lint opam file whatever-lib.opam.
    [ OK ] opam field description is present
    [ OK ] opam fields homepage and dev-repo can be parsed by dune-release
    [ OK ] Skipping doc field linting, no doc field found
    [ OK ] lint _build/whatever-0.1.0 success
    
    [-] Building package in _build/whatever-0.1.0
    => chdir _build/whatever-0.1.0
    -: exec: dune build -p whatever,whatever-lib
    [ OK ] package builds
    
    [-] Running package tests in _build/whatever-0.1.0
    => chdir _build/whatever-0.1.0
    -: exec: dune runtest -p whatever,whatever-lib
    [ OK ] package tests
    -: rmdir _build/whatever-0.1.0
    
    [+] Distribution for whatever 0.1.0
    [+] Commit ...
    [+] Archive _build/whatever-0.1.0.tbz

We publish the documentation, calling publish doc explicitely should fail

    $ dune-release publish doc
    [-] Publishing documentation
    [-] Selected packages: whatever whatever-lib
    [-] Generating documentation from _build/whatever-0.1.0.tbz
    [-] Publishing to github
    dune-release: [ERROR] Could not derive publication directory $PATH from opam doc field value ""; expected the pattern $SCHEME://$USER.github.io/$REPO/$PATH
    [3]

We do the whole process, calling publish doc implicitely should succeed

    $  yes "" | dune-release --dry-run
    [-] Building source archive
    => rmdir _build/whatever-0.1.0.build
    -: exec: git --git-dir .git rev-parse --verify 0.1.0
    => exec: git --git-dir .git show -s --format=%ct 0.1.0^{commit}
    => exec: git --git-dir .git clone --local .git _build/whatever-0.1.0.build
    => exec:
         git --git-dir _build/whatever-0.1.0.build/.git --work-tree   _build/whatever-0.1.0.build/ checkout --quiet -b dune-release-dist-0.1.0   0.1.0
    => chdir _build/whatever-0.1.0.build
       [in _build/whatever-0.1.0.build]
    -: exec: dune subst
    -: write whatever.opam
    -: write whatever-lib.opam
    => exec: bzip2
    -: rmdir _build/whatever-0.1.0.build
    [+] Wrote archive _build/whatever-0.1.0.tbz
    => chdir _build/
       [in _build]
    => rmdir _build/whatever-0.1.0
    => exec: tar -xjf whatever-0.1.0.tbz
    
    [-] Linting distrib in _build/whatever-0.1.0
    => chdir _build/whatever-0.1.0
       [in _build/whatever-0.1.0]
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
    [ OK ] lint _build/whatever-0.1.0 success
    => chdir _build/whatever-0.1.0
    => exists ./README
    [ OK ] File README is present.
    => exists ./LICENSE
    [ OK ] File LICENSE is present.
    => exists ./CHANGES.md
    [ OK ] File CHANGES is present.
    => exists whatever-lib.opam
    [ OK ] File opam is present.
    -: exec: opam lint -s whatever-lib.opam
    [ OK ] lint opam file whatever-lib.opam.
    [ OK ] opam field description is present
    [ OK ] opam fields homepage and dev-repo can be parsed by dune-release
    [ OK ] Skipping doc field linting, no doc field found
    [ OK ] lint _build/whatever-0.1.0 success
    
    [-] Building package in _build/whatever-0.1.0
    => chdir _build/whatever-0.1.0
    -: exec: dune build -p whatever,whatever-lib
    [ OK ] package builds
    
    [-] Running package tests in _build/whatever-0.1.0
    => chdir _build/whatever-0.1.0
    -: exec: dune runtest -p whatever,whatever-lib
    [ OK ] package tests
    -: rmdir _build/whatever-0.1.0
    
    [+] Distribution for whatever 0.1.0
    [+] Commit ...
    [+] Archive _build/whatever-0.1.0.tbz
    [-] Skipping documentation publication for package whatever: no doc field in whatever.opam
    [-] Publishing distribution
    => must exists _build/whatever-0.1.0.tbz
    [-] Publishing to github
    -: exec: git --git-dir .git rev-parse --verify 0.1.0
    -: exec: git --git-dir .git rev-parse --verify 0.1.0
    [?] Push tag 0.1.0 to git@github.com:foo/whatever.git? [Y/n]
    [-] Pushing tag 0.1.0 to git@github.com:foo/whatever.git
    -: exec: git --git-dir .git push --force git@github.com:foo/whatever.git 0.1.0
    ...
    [?] Create release 0.1.0 on git@github.com:foo/whatever.git? [Y/n]
    [-] Creating release 0.1.0 on git@github.com:foo/whatever.git via github's API
    -: exec: curl --user foo:${token} --location --silent --show-error --config -
         --dump-header - --data
         { "tag_name" : "0.1.0", "body" : "CHANGES:\n\n- Some other feature\n" }
    [+] Succesfully created release with id 1
    [?] Upload _build/whatever-0.1.0.tbz as release asset? [Y/n]
    [-] Uploading _build/whatever-0.1.0.tbz as a release asset for 0.1.0 via github's API
    -: exec: curl --user foo:${token} --location --silent --show-error --config -
         --dump-header - --header Content-Type:application/x-tar --data-binary
         @_build/whatever-0.1.0.tbz
    -: write _build/whatever-0.1.0.url
    => must exists _build/whatever-0.1.0.tbz
    [-] Creating opam package description for whatever
    dune-release: [WARNING] Could not find _build/whatever-0.1.0.url.
    dune-release: [WARNING] using https://github.com/foo/whatever/releases/download/0.1.0/whatever-0.1.0.tbz for as url.src. Note that it might differ from the one generated by Github
    [+] Wrote opam package description _build/whatever.0.1.0/opam
    [-] Creating opam package description for whatever-lib
    dune-release: [WARNING] Could not find _build/whatever-lib-0.1.0.url.
    dune-release: [WARNING] using https://github.com/foo/whatever/releases/download/0.1.0/whatever-0.1.0.tbz for as url.src. Note that it might differ from the one generated by Github
    [+] Wrote opam package description _build/whatever-lib.0.1.0/opam
    ...
    [-] Submitting
    ...
    => exists _build/whatever.0.1.0
    => exists _build/whatever-lib.0.1.0
    [-] Preparing pull request to ocaml/opam-repository
    ...
    [-] Fetching https://github.com/ocaml/opam-repository.git#master
    => exec:
         git --git-dir .git fetch https://github.com/ocaml/opam-repository.git master
    => exec: git --git-dir .git rev-parse FETCH_HEAD
    [-] Checking out a local release-whatever-0.1.0 branch
    => exec: git --git-dir .git add packages/whatever/whatever.0.1.0
    => exec: git --git-dir .git add packages/whatever-lib/whatever-lib.0.1.0
    -: exec:
    ...
    -: exec:
    ...
    [?] Open PR to ocaml/opam-repository? [Y/n]
    ...
    -: exec: curl --user foo:${token} --silent --show-error --config - --dump-header
         - --data
    ...
    -: exec: xdg-open ${pr_url}
