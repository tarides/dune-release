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

Most of the code in this repository has been written by
Daniel Bünzli and has already been released part of the
[topkg](http://erratique.ch/software/topkg) tool.

`dune-release` removes the IPC layer of `topkg` and bundle everything
as a single binary. It removes the need to define `pkg/pkg.ml` and
assumes that the package is built using
[dune](https://github.com/ocaml/dune).
