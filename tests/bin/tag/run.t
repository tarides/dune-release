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
  $ touch whatever.opam
  $ cat > dune-project << EOF
  > (lang dune 2.4)
  > (name whatever)
  > EOF

We need to set up a git project with two commits to test trying to tag different commits with the same tag name.

  $ git init > /dev/null
  $ git add whatever.opam dune-project
  $ git commit -m "Initial commit" > /dev/null
  $ git add CHANGES.md
  $ git commit -m "Add CHANGES.md" > /dev/null

Running `dune-release tag` for the first time should tag HEAD with the current version number.

  $ dune-release tag -y
  [-] Extracting tag from first entry in CHANGES.md
  [-] Using tag "0.1.0"
  [+] Tagged HEAD with version 0.1.0

Checking the message attached to the tag.

  $ git show 0.1.0 | tail -n +5 | head -n 5
  Distribution 0.1.0
  
  CHANGES:
  
  - Some other feature

Running `dune-release tag` again should inform the user that that tag already exists.

  $ dune-release tag
  [-] Extracting tag from first entry in CHANGES.md
  [-] Using tag "0.1.0"
  [-] Nothing to be done: tag already exists.

Running `dune-release tag` again, but providing a different commit should inform the user that that tag already exists but points to a different commit.

  $ dune-release tag --commit=HEAD^
  [-] Extracting tag from first entry in CHANGES.md
  [-] Using tag "0.1.0"
  dune-release: [ERROR] A tag with name 0.1.0 already exists, but points to a different commit. You can delete that tag using the `-d` flag.
  [3]

Trying to delete the created tag providing a different commit should give a warning. The answer to the question 
asking for confirmation should default to "no".

  $ echo "" | dune-release tag -d --commit=HEAD^
  [-] Extracting tag from first entry in CHANGES.md
  [-] Using tag "0.1.0"
  [?] Warning: Tag 0.1.0 does not point to the commit you've provided (default: HEAD). Do you want to delete it anyways? [y/N]
  dune-release: [ERROR] Aborting on user demand
  [3]

Deleting the created tag providing the commit it points to (here the default, so HEAD) should work without warning. 
The answer to the question asking for confirmation should default to "yes".

  $ echo "" | dune-release tag -d
  [-] Extracting tag from first entry in CHANGES.md
  [-] Using tag "0.1.0"
  [?] Delete tag 0.1.0? [Y/n]
  [+] Deleted tag 0.1.0

Trying to delete a commit that doesn't exist should inform the user that there's nothing to be deleted.

  $ dune-release tag -d -y
  [-] Extracting tag from first entry in CHANGES.md
  [-] Using tag "0.1.0"
  [-] Nothing to be deleted: there is no tag 0.1.0.
