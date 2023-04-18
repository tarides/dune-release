Set up a project with an `.opam` file in the toplevel folder:

  $ cat > CHANGES.md << EOF
  > ## 0.1.0
  > 
  > - Initial release
  > 
  > EOF
  $ cat > dune-project << EOF
  > (lang dune 3.8)
  > (name myproject)
  > EOF
  $ cat > myproject.opam << EOF
  > opam-version: "2.0"
  > EOF
  $ git init 2> /dev/null . > /dev/null
  $ touch README LICENSE
  $ cat > .gitignore << EOF
  > _build
  > .bin
  > /dune
  > run.t
  > EOF
  $ git add CHANGES.md README LICENSE *.opam dune-project .gitignore
  $ git commit -m 'Initial commit' > /dev/null

Tagging should work

  $ dune-release tag -y
  [-] Extracting tag from first entry in CHANGES.md
  [-] Using tag "0.1.0"
  [+] Tagged HEAD with version 0.1.0

`dune-release distrib` should work.

  $ dune-release distrib --skip-lint | make_dune_release_deterministic
  [-] Building source archive
  [+] Wrote archive _build/myproject-0.1.0.tbz
  
  [-] Building package in _build/myproject-0.1.0
  [ OK ] package(s) build
  
  [-] Running package tests in _build/myproject-0.1.0
  [ OK ] package(s) pass the tests
  
  [+] Distribution for myproject 0.1.0
  [+] Commit <deterministic>
  [+] Archive _build/myproject-0.1.0.tbz

Now let's move the `.opam` file to the `opam/` subfolder. OPAM supports `.opam`
files in the `opam/` subfolder, but for dune to pick it up we need to tell it
to look in that folder.

Importantly, dune requires the packages in the `opam/` folder to be declared in
`dune-project` as `package`.

  $ mkdir opam
  $ git mv myproject.opam opam/
  $ cat  > CHANGES.md << EOF
  > ## 0.2.0
  > 
  > - Move opam file to opam folder
  > 
  > EOF
  $ cat >> dune-project << EOF
  > (package
  >   (name myproject)
  >   (allow_empty))
  > (opam_file_location inside_opam_directory)
  > EOF
  $ git add opam/myproject.opam CHANGES.md dune-project
  $ git commit -m 'Moved opam file' > /dev/null

Now we should still be able to tag:

  $ dune-release tag -y
  [-] Extracting tag from first entry in CHANGES.md
  [-] Using tag "0.2.0"
  [+] Tagged HEAD with version 0.2.0

And as well have a release tarball

  $ dune-release distrib --skip-lint | make_dune_release_deterministic
  [-] Building source archive
  [+] Wrote archive _build/myproject-0.2.0.tbz
  
  [-] Building package in _build/myproject-0.2.0
  [ OK ] package(s) build
  
  [-] Running package tests in _build/myproject-0.2.0
  [ OK ] package(s) pass the tests
  
  [+] Distribution for myproject 0.2.0
  [+] Commit <deterministic>
  [+] Archive _build/myproject-0.2.0.tbz

Which contains the `.opam` file in the right location:

  $ tar tf _build/myproject-0.2.0.tbz | grep \\.opam
  myproject-0.2.0/opam/myproject.opam
