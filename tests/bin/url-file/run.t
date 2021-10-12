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
  > synopsis: "whatever"
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
  > .formatted
  > /dune
  > run.t
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

We make a dry-run release:

(1) Creating the distribution archive

  $ dune-release distrib --dry-run | grep -vE "Commit [a-f0-9]{40}"
  [-] Building source archive
  => rmdir _build/whatever-0.1.0.build
  -: exec: git --git-dir .git rev-parse --verify refs/tags/0.1.0
  => exec: git --git-dir .git show -s --format=%ct 0.1.0^0
  => exec: git --git-dir .git clone --local .git _build/whatever-0.1.0.build
  => exec:
       git --git-dir _build/whatever-0.1.0.build/.git --work-tree   _build/whatever-0.1.0.build/ checkout --quiet -b dune-release-dist-0.1.0   0.1.0
  => chdir _build/whatever-0.1.0.build
     [in _build/whatever-0.1.0.build]
  -: exec: dune subst
  -: write whatever.opam
  => exec: bzip2
  -: rmdir _build/whatever-0.1.0.build
  [+] Wrote archive _build/whatever-0.1.0.tbz
  => chdir _build/
     [in _build]
  => exec: tar -xjf whatever-0.1.0.tbz
  
  [-] Performing lint for package whatever in _build/whatever-0.1.0
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
  [ OK ] opam field synopsis is present
  [ OK ] opam fields homepage and dev-repo can be parsed by dune-release
  [ OK ] Skipping doc field linting, no doc field found
  [ OK ] lint of _build/whatever-0.1.0 and package whatever success
  
  [-] Building package in _build/whatever-0.1.0
  => chdir _build/whatever-0.1.0
  -: exec: dune build -p whatever
  [ OK ] package(s) build
  
  [-] Running package tests in _build/whatever-0.1.0
  => chdir _build/whatever-0.1.0
  -: exec: dune runtest -p whatever
  [ OK ] package(s) pass the tests
  -: rmdir _build/whatever-0.1.0
  
  [+] Distribution for whatever 0.1.0
  [+] Archive _build/whatever-0.1.0.tbz


(2) Publihsing the distribution

  $ yes | dune-release publish --dry-run | grep -v github.token
  [-] Skipping documentation publication for package whatever: no doc field in whatever.opam
  [-] Publishing distribution
  => must exists _build/whatever-0.1.0.tbz
  [-] Publishing to github
  -: exec: git --git-dir .git rev-parse --verify refs/tags/0.1.0
  -: exec: git --git-dir .git rev-parse --verify refs/tags/0.1.0
  -: exec:
       git --git-dir .git ls-remote --quiet --tags   https://github.com/foo/whatever.git 0.1.0
  [?] Push tag 0.1.0 to git@github.com:foo/whatever.git? [Y/n]
  [-] Pushing tag 0.1.0 to git@github.com:foo/whatever.git
  -: exec: git --git-dir .git push --force git@github.com:foo/whatever.git 0.1.0
  -: exec: curl --header Authorization: token ${token} --location --silent
       --show-error --config - --dump-header -
  [?] Create release 0.1.0 on https://github.com/foo/whatever.git? [Y/n]
  [-] Creating release 0.1.0 on https://github.com/foo/whatever.git via github's API
  -: exec: curl --header Authorization: token ${token} --location --silent
       --show-error --config - --dump-header - --data
       {"tag_name":"0.1.0","name":"0.1.0","body":"CHANGES:\n\n- Some other feature\n","draft":false}
  [+] Successfully created release with id 1
  [?] Upload _build/whatever-0.1.0.tbz as release asset? [Y/n]
  [-] Uploading _build/whatever-0.1.0.tbz as a release asset for 0.1.0 via github's API
  -: exec: curl --header Authorization: token ${token} --location --silent
       --show-error --config - --dump-header - --header
       Content-Type:application/x-tar --data-binary @_build/whatever-0.1.0.tbz
  -: write _build/asset-0.1.0.url


(3) Creating an opam package

  $ echo "https://foo.fr/archive/foo/foo.tbz" > _build/asset-0.1.0.url

  $ dune-release opam pkg
  [-] Creating opam package description for whatever
  [+] Wrote opam package description _build/whatever.0.1.0/opam

  $ cat _build/whatever.0.1.0/opam | sed -e 's/\(x-commit-hash:\) "[0-9a-f]*"/\1/' | sed -n '1h;1!H;${g;s/checksum: \[.*\]/checksum: []/;p;}'
  opam-version: "2.0"
  homepage: "https://github.com/foo/whatever"
  dev-repo: "git+https://github.com/foo/whatever.git"
  synopsis: "whatever"
  url {
    src: "https://foo.fr/archive/foo/foo.tbz"
    checksum: []
  }
  x-commit-hash:
