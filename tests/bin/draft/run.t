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
    [-] Using tag "0.1.0"
    [+] Tagged HEAD with version 0.1.0

We do the whole dune-release process

(1) distrib

    $ dune-release distrib --dry-run > /dev/null

(2) publish

    $ yes | dune-release publish --dry-run --draft
    [-] Skipping documentation publication for package whatever: no doc field in whatever.opam
    [-] Publishing distribution
    => must exists _build/whatever-0.1.0.tbz
    [-] Publishing to github
    ...
    -: exec: git --git-dir .git rev-parse --verify 0.1.0
    -: exec:
         git --git-dir .git ls-remote --quiet --tags   https://github.com/foo/whatever.git 0.1.0
    [?] Push tag 0.1.0 to git@github.com:foo/whatever.git? [Y/n]
    [-] Pushing tag 0.1.0 to git@github.com:foo/whatever.git
    -: exec: git --git-dir .git push --force git@github.com:foo/whatever.git 0.1.0
    ...
    [?] Create draft release 0.1.0 on https://github.com/foo/whatever.git? [Y/n]
    [-] Creating draft release 0.1.0 on https://github.com/foo/whatever.git via github's API
    -: exec: curl --user foo:${token} --location --silent --show-error --config -
         --dump-header - --data
         {"tag_name":"0.1.0","name":"0.1.0","body":"CHANGES:\n\n- Some other feature\n","draft":true}
    [+] Successfully created draft release with id 1
    -: write _build/whatever-0.1.0.draft_release
    [?] Upload _build/whatever-0.1.0.tbz as release asset? [Y/n]
    [-] Uploading _build/whatever-0.1.0.tbz as a release asset for 0.1.0 via github's API
    -: exec: curl --user foo:${token} --location --silent --show-error --config -
         --dump-header - --header Content-Type:application/x-tar --data-binary
         @_build/whatever-0.1.0.tbz
    -: write _build/whatever-0.1.0.release_asset_name
    -: write _build/whatever-0.1.0.url
