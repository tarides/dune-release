A necessary condition for dune-release to work is that it's able to infer the main package

  $ touch first_pkg.opam
  $ touch other_pkg.opam

  $ dune-release check --working-tree
  [FAIL] cannot determine distribution name automatically: add (name <name>) to dune-project
  [1]

Make a minimal project set up

  $ rm first_pkg.opam other_pkg.opam
  $ cat > my_pkg.opam <<EOF
  > opam-version: "2.0"
  > dev-repo: "git+https://github.com/fu/fa.git"
  > description : "Some description"
  > maintainer : "me"
  > authors : "also me"
  > homepage : "https://github.com/fu/fa"
  > bug-reports : "https://github.com/fu/fa/issues"
  > synopsis : "Dope project"
  > EOF
  $ cat > dune-project << EOF 
  > (lang dune 2.7)
  > (name my_pkg)
  > EOF
  $ git config remote.origin.url git+https://github.com/fu/fa.git

If the condition described above is fulfilled, there are 4 checks to be performed

  $ dune-release check --working-tree | make_dune_release_deterministic
  [-] Checking dune-release compatibility.
  [ OK ] The dev-repo field of my_pkg.opam contains a github uri.
  [ OK ] The dune project contains a name stanza.
  
  [-] Building package in <test_directory>
  [ OK ] package(s) build
  
  [-] Running package tests in <test_directory>
  [ OK ] package(s) pass the tests
  
  [-] Performing lint for package my_pkg in <test_directory>
  [FAIL] File README is missing.
  [FAIL] File LICENSE is missing.
  [FAIL] File CHANGES is missing.
  [ OK ] File opam is present.
  [ OK ] lint opam file my_pkg.opam.
  [ OK ] opam field synopsis is present
  [ OK ] opam fields homepage and dev-repo can be parsed by dune-release
  [ OK ] Skipping doc field linting, no doc field found
  [FAIL] lint of <project_dir> and package my_pkg failure: 3 errors.

Add another package

  $ cat > my_pkg-sub.opam <<EOF 
  > opam-version: "2.0"
  > dev-repo: "git+https://github.com/fu/fa.git"
  > description : "Some description"
  > maintainer : "me"
  > authors : "also me"
  > homepage : "https://github.com/fu/fa"
  > bug-reports : "https://github.com/fu/fa/issues"
  > synopsis : "Dope project"
  > EOF

In multi package projects, the whole lint process (including the file lints, even though they are package independent) is done once for every package

  $ dune-release check --working-tree | make_dune_release_deterministic
  [-] Checking dune-release compatibility.
  [ OK ] The dev-repo field of my_pkg.opam contains a github uri.
  [ OK ] The dune project contains a name stanza.
  
  [-] Building package in <test_directory>
  [ OK ] package(s) build
  
  [-] Running package tests in <test_directory>
  [ OK ] package(s) pass the tests
  
  [-] Performing lint for package my_pkg in <test_directory>
  [FAIL] File README is missing.
  [FAIL] File LICENSE is missing.
  [FAIL] File CHANGES is missing.
  [ OK ] File opam is present.
  [ OK ] lint opam file my_pkg.opam.
  [ OK ] opam field synopsis is present
  [ OK ] opam fields homepage and dev-repo can be parsed by dune-release
  [ OK ] Skipping doc field linting, no doc field found
  [FAIL] lint of <project_dir> and package my_pkg failure: 3 errors.
  
  [-] Performing lint for package my_pkg-sub in <test_directory>
  [FAIL] File README is missing.
  [FAIL] File LICENSE is missing.
  [FAIL] File CHANGES is missing.
  [ OK ] File opam is present.
  [ OK ] lint opam file my_pkg-sub.opam.
  [ OK ] opam field synopsis is present
  [ OK ] opam fields homepage and dev-repo can be parsed by dune-release
  [ OK ] Skipping doc field linting, no doc field found
  [FAIL] lint of <project_dir> and package my_pkg-sub failure: 3 errors.

In the same way in which the user can skip the lint check when releasing the tarball, they can also skip it here

  $ dune-release check --working-tree --skip-lint | make_dune_release_deterministic
  [-] Checking dune-release compatibility.
  [ OK ] The dev-repo field of my_pkg.opam contains a github uri.
  [ OK ] The dune project contains a name stanza.
  
  [-] Building package in <test_directory>
  [ OK ] package(s) build
  
  [-] Running package tests in <test_directory>
  [ OK ] package(s) pass the tests

Same for skipping the tests

  $ dune-release check --working-tree --skip-lint --skip-test | make_dune_release_deterministic
  [-] Checking dune-release compatibility.
  [ OK ] The dev-repo field of my_pkg.opam contains a github uri.
  [ OK ] The dune project contains a name stanza.
  
  [-] Building package in <test_directory>
  [ OK ] package(s) build

Same for skipping the build (which implies skipping the tests)

  $ dune-release check --working-tree --skip-lint --skip-build
  [-] Checking dune-release compatibility.
  [ OK ] The dev-repo field of my_pkg.opam contains a github uri.
  [ OK ] The dune project contains a name stanza.

Create a project with an opam file without dev-repo field

  $ rm my_pkg.opam my_pkg-sub.opam dune-project
  $ echo "opam-version: \"2.0\"" > my_pkg.opam

If the main opam file doesn't contain a dev-repo field, the first check fails

  $ dune-release check --skip-lint --skip-build --working-tree
  [-] Checking dune-release compatibility.
  [FAIL] main package my_pkg.opam is not dune-release compatible. Github development repository URL could not be inferred from opam files.
  Have you provided a github uri in the dev-repo field of your main opam file? If you don't use github, you can still use dune-release for everything but for publishing your release on the web. In that case, have a look at `dune-release delegate-info`.
  [FAIL] The dune project doesn't contain a name stanza. Please, add one.

Add an invalid dev-repo field to the opam file

  $ cat > my_pkg.opam << EOF 
  > opam-version: "2.0"
  > dev-repo: "https://my_homepage.com"
  > EOF

The first check also fails, if the opam file does contain a dev-repo field, but that field isn't in the format of a github dev repo

  $ dune-release check --skip-lint --skip-build --working-tree
  [-] Checking dune-release compatibility.
  [FAIL] main package my_pkg.opam is not dune-release compatible. Github development repository URL could not be inferred from opam files.
  Have you provided a github uri in the dev-repo field of your main opam file? If you don't use github, you can still use dune-release for everything but for publishing your release on the web. In that case, have a look at `dune-release delegate-info`.
  [FAIL] The dune project doesn't contain a name stanza. Please, add one.

Create a sub-opam file with a valid dev-repo field

  $ cat > my_pkg-ppx.opam << EOF 
  > opam-version: "2.0"
  > dev-repo: "git+https://github.com/fu/fa.git"
  > EOF

The first check only depends on the main package; all subpackages are irrelevant

  $ dune-release check --skip-lint --skip-build --working-tree
  [-] Checking dune-release compatibility.
  [FAIL] main package my_pkg.opam is not dune-release compatible. Github development repository URL could not be inferred from opam files.
  Have you provided a github uri in the dev-repo field of your main opam file? If you don't use github, you can still use dune-release for everything but for publishing your release on the web. In that case, have a look at `dune-release delegate-info`.
  [FAIL] The dune project doesn't contain a name stanza. Please, add one.

Add a name stanza to the dune-project

  $ cat > dune-project <<EOF 
  > (lang dune 2.8) 
  > (name my_pkg-ppx) 
  > EOF

Which package the main package is can be made clear in the dune-project.
With that, also the second compatibility test passes.

  $ dune-release check --skip-lint --skip-build --working-tree
  [-] Checking dune-release compatibility.
  [ OK ] The dev-repo field of my_pkg-ppx.opam contains a github uri.
  [ OK ] The dune project contains a name stanza.

Make a project which is dune-release compatible on the working tree,
but not dune-release compatible on the last git tag.

  $ rm my_pkg.opam my_pkg-ppx.opam dune-project
  $ echo "opam-version: \"2.0\"" > my_pkg.opam

  $ git init 2> /dev/null > /dev/null
  $ git config user.name "dune-release-test"
  $ git config user.email "pseudo@pseudo.invalid"
  $ git config remote.origin.url git+https://github.com/foo/whatever.git
  $ git add my_pkg.opam
  $ git commit -m "Initial commit" > /dev/null
  $ git tag -a 0.1.0 HEAD -m "release 0.1.0"

  $ echo "dev-repo: \"git+https://github.com/fu/fa.git\"" >> my_pkg.opam
  $ cat > dune-project << EOF 
  > (lang dune 2.7)
  > (name my_pkg)
  > EOF

The [--working-tree] option used so far, makes `check` be run on the working tree.

  $ dune-release check --skip-lint --skip-build --working-tree
  [-] Checking dune-release compatibility.
  [ OK ] The dev-repo field of my_pkg.opam contains a github uri.
  [ OK ] The dune project contains a name stanza.

 By default, `check` runs on a tag - either the one provided by [--tag] or [--version],
 or the last tag on HEAD.

  $ dune-release check --skip-lint --skip-build
  [-] Checking dune-release compatibility.
  [FAIL] main package my_pkg.opam is not dune-release compatible. Github development repository URL could not be inferred from opam files.
  Have you provided a github uri in the dev-repo field of your main opam file? If you don't use github, you can still use dune-release for everything but for publishing your release on the web. In that case, have a look at `dune-release delegate-info`.
  [FAIL] The dune project doesn't contain a name stanza. Please, add one.
