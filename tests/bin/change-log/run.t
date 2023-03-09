Generate a change log to parse

  $ cat > CHANGES.md <<EOF
  > Changelog
  > =========
  > 
  > ## v0.1.0
  > 
  > - some other feature
  > 
  > ## v0.0.0
  > 
  > - some feature
  > 
  > EOF

  $ touch foo.opam

  $ dune-release change-log
  Tag: v0.1.0
  Title: ## v0.1.0
  Body:
  - some other feature
