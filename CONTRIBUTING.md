## Releasing caretaker

1. Make sure the tests are passing
     `dune runtest`
2. Make sure the lint is passing
     `dune-release lint`
3. Update the version number in the [CHANGES.md](https://github.com/tarides/caretaker/blob/main/CHANGES.md) file
     - Replace `unreleased` with the actual version number.
     - Follow the [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html) specification.
     - Push the changes and rebase your local branch.
4. Create the tag
     - `dune-release tag`
     - `git push --tags upstream main`
5. Create the release
```
dune-release \
  --opam-repo ORG/opam-repository \
  --remote-repo git@github.com:YOU/your-opam-repository \
  --local-repo /path/to/your/opam-repo/fork
```
