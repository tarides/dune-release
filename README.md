## dune-release

```
$ dune-release help release

NAME
       dune-release - How to release a (dune) package

DESCRIPTION
       The basic release script is the following. Each step is refined and
       explained with more details below.

       dune-release browse issues # Review remaining outstanding issues
       dune-release status        # Review the changes since last version
       dune-release log edit      # Write the release notes
       dune-release log commit    # Commit the release notes
       dune-release tag           # Tag the distribution with a version
       dune-release distrib       # Create the distribution archive
       dune-release publish       # Publish it on the WWW with its documentation
       dune-release opam pkg      # Create an opam package
       dune-release opam submit   # Submit it to OCaml's opam repository

       The last four steps can be performed via a single invocation to
       dune-release-bistro(1).
```

Consult the manual for details.

### Important Notes

Most of the code in this repository has been written and has already
been released part of the [topkg](http://erratique.ch/software/topkg)
tool.

The main differences between `topkg` and `dune-release` are:

- Use of `Astring`, `Logs`, `Fpath` and`Bos` instead of custom
  re-implementations in `Topkg`;
- The removal the IPC layer which is used between `topkg` and
  `topkg-care`;
- Bundle everything as a single binary
- `dune-release` does not need a `pkg/pkg.ml`but it assumes that
  the package is built using [dune](https://github.com/ocaml/dune).
