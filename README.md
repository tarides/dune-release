## dune-release: release dune packages in opam

`dune-release` is a tool to streamline the release of Dune packages in
[opam](https://opam.ocaml.org). It supports only projects be built
with [Dune](https://github.com/ocaml/dune) and released on
[GitHub](https://github.com).

## Installation

`dune-release` can be installed with `opam`:

```
opam install dune-release
```

## Documentation

The `dune-release` command line tool is extensively documented in man pages
available through it's help system. Type:

```
dune-release help release # for help about releasing your package
dune-release help         # for more help
```

Calling `dune-release` without any argument will start the automated release process, composed of the following steps:
- create the distribution archive;
- publish it online with its documentation;
- create an opam package;
- submit it to OCaml's opam repository.

The most basic workflow is:

```
dune-release tag
dune-release
```

Each step is refined and explained with more details below.
If this is your first time using `dune-release` you might choose to run the `dune-release` commands with the `--dry-run` argument, so that no action is actually performed but it allows you to check what would be done. And then run the `dune-release` commands without `--dry-run` when you are sure of what you are doing.


### Tag the distribution with a version

This step should be executed prior to running the `dune-release` automated process.

The tagging command of `dune-release` will extract the latest version tag from the package's change log and tag the VCS HEAD commit with it if it is invoked without argument:

```
dune-release tag
```

This will only work if the change log follows a certain format. If you do not want to rely on this extraction you can specify it on the command line:

```
dune-release tag v1.0.1
```

You can also directly use your VCS instead if the `dune-release tag` command does not fit your needs.

If you need to delete a tag created by `dune-release`, use the following command:

```
dune-release tag -d v1.0.1
```

The full documentation of this command is available with
```
dune-release help tag
```


### Create the distribution archive

Now that the release is tagged in your VCS, generate a distribution archive for it in the build directory with:

```
dune-release distrib
```

This uses the source tree of the HEAD commit for creating a distribution in the build directory. The distribution version string is the VCS tag description (e.g. `git-describe`) of the HEAD commit. Alternatively it can be specified on the command line.

Basic checks are performed on the distribution archive when it is created, but save time by catching errors early. Hence test that your source repository lints and that it builds in the current build environment and that the package tests pass.

```
dune-release lint
dune build # Check out the generated opam install file too
dune runtest
```

The full documentation of this command is available with
```
dune-release help distrib
```


### Publish the distribution and documentation online

Once the distribution archive is created you can now publish it and its documentation online.

```
dune-release publish
```

You can publish the archive only with:

```
dune-release publish distrib
```

or publish the documentation only with:

```
dune-release publish doc
```

The full documentation of this command is available with
```
dune-release help publish
```


### Create an opam package

The following steps still need the distribution archive created in the preceeding step to be in the build directory. If that's no longer the case but nothing moved in your VCS, you can simply invoke dune-release distrib, it should produce a bit-wise identical archive. If the VCS moved checkout the distribution commit to regenerate the archive or provide, in the subsequent commands, the archive manually via the `--dist-file` option.

To add the package to OCaml's opam repository, start by creating an opam package description in the build directory with:

```
dune-release opam pkg
```

### Submit the opam package to the opam repository

To submit the package to the [opam repository](https://github.com/ocaml/opam-repository):

```
dune-release opam submit
```

The latter does nothing more than invoking `opam publish submit` on the package description generated earlier.


The full documentation of this command is available with
```
dune-release help opam
```


### Important Notes

Most of the code in this repository has been written and has already
been released part of the [topkg](http://erratique.ch/software/topkg)
tool.

The main differences between `dune-release` and `topkg` are:

- Remove `pkg/pkg.ml`;
- Assume the project is built with [dune](https://github.com/ocaml/dune);
- Bundle everything as a single binary;
- Use of `Astring`, `Logs`, `Fpath` and`Bos`;
- Remove the IPC layer (which is used between `topkg` and `topkg-care`);
