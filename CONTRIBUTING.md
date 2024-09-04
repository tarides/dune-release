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
     - `make release`
6. Commit the changes in [tarides/opam-repository](https://github.com/tarides/opam-repository)
7. Update [update-data.yml](https://github.com/tarides/admin/blob/main/.github/workflows/update-data.yml) to use the new caretaker version
