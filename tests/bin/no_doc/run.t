We need a basic opam project skeleton with an empty doc field

  $ cat > CHANGES.md << EOF
  > ## 0.1.0
  > 
  >  - Change A   
  >  - Change B
  > 
  > ## 0.0.0
  > 
  > - Some feature
  > EOF
  $ cat > whatever.opam << EOF
  > opam-version: "2.0"
  > homepage: "https://github.com/foo/whatever"
  > dev-repo: "git+https://github.com/foo/whatever.git"
  > description: "whatever"
  > EOF
  $ cat > whatever-lib.opam << EOF
  > opam-version: "2.0"
  > homepage: "https://github.com/foo/whatever"
  > dev-repo: "git+https://github.com/foo/whatever.git"
  > description: "whatever-lib"
  > doc: ""
  > EOF
  $ touch README
  $ touch LICENSE
  $ cat > dune-project << EOF
  > (lang dune 2.4)
  > (name whatever)
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
  -: must exists _build/whatever-0.1.0.tbz
  -: chdir _build/
  -: exec: tar -xjf whatever-0.1.0.tbz
  dune-release: [ERROR] directory contents _build/whatever-0.1.0: No such file or directory
  [3]

By default it should skip the documentation generation:

  $ dune-release publish -y --dry-run | ../sanitize.sh
  [-] Skipping documentation publication for package whatever: no doc field in whatever.opam
  [-] Publishing distribution
  -: must exists _build/whatever-0.1.0.tbz
  [-] Publishing to github
  -: exec: git --git-dir .git rev-parse --verify 0.1.0
  -: exec: git --git-dir .git rev-parse --verify 0.1.0
  -: exec:
       git --git-dir .git ls-remote --quiet --tags   https://github.com/foo/whatever.git 0.1.0
  [-] Pushing tag 0.1.0 to git@github.com:foo/whatever.git
  -: exec: git --git-dir .git push --force git@github.com:foo/whatever.git 0.1.0
  [-] Creating release 0.1.0 on https://github.com/foo/whatever.git via github's API
  -: exec: curl --user foo:${token} --location --silent --show-error --config -
       --dump-header - --data
       { "tag_name" : "0.1.0", "body" : "CHANGES:\n\n - Change A\n - Change B\n" }
  [+] Succesfully created release with id 1
  [-] Uploading _build/whatever-0.1.0.tbz as a release asset for 0.1.0 via github's API
  -: exec: curl --user foo:${token} --location --silent --show-error --config -
       --dump-header - --header Content-Type:application/x-tar --data-binary
       @_build/whatever-0.1.0.tbz
  -: write _build/whatever-0.1.0.url
