[![Build Status](https://img.shields.io/endpoint?url=https%3A%2F%2Fci.ocamllabs.io%2Fbadge%2Focamllabs%2Fdune-release%2Fmaster&logo=ocaml)](https://ci.ocamllabs.io/github/ocamllabs/dune-release)

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

If the repository contains multiple opam packages, `dune-release` will try to release all of them by default (ie. one tarball, one github release but several opam files added to the opam repository).

The most basic workflow is:

```
dune-release tag
dune-release
```

Each step is refined and explained with more details below.
By default `dune-release` asks for permission before taking any significant action so you should not be afraid of running it.


### Tag the distribution with a version

This step should be executed prior to running the `dune-release` automated process.

The tagging command of `dune-release` will extract the latest version tag from the package's change log and tag the VCS HEAD commit with it if it is invoked without argument:

```
dune-release tag
```

This will only work if the change log follows a certain format.
The version number must be in the first item of the change log file (usually a section title). Asciidoc and Markdown files are supported. A typical example of such version in a markdown file is:

```
## v1.0.1 (2019-09-30)
```

The version extracted from this change log will be `v1.0.1`. This will be used to infer the tag of the release as well as generate the publication message. If you do not want to rely on this extraction you can specify it on the command line:

```
dune-release tag v1.0.1
```

You can also directly use your VCS instead if the `dune-release tag` command does not fit your needs.
Note that `dune-release` and `dune` only work with annotated tags (i.e. tags created with
`git tag -a`) and that if you want to take care of the tagging yourself you should take this into
account.

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

This uses the source tree of the HEAD commit for creating a distribution in the build directory.
Note that any uncommitted change will therefore be ignored. The distribution version string is the
VCS tag description (e.g. `git-describe`) of the HEAD commit. Alternatively it can be specified on
the command line.

Basic checks are performed on the distribution archive when it is created, but save time by catching
errors early. Hence test that your source repository lints and that it builds in the current build
environment and that the package tests pass.

```
dune-release check
```

The full documentation of this command is available with
```
dune-release help distrib
```


### Publish the distribution and documentation online

Once the distribution archive is created you can now publish it and its documentation online.

You can publish the archive only with:

```
dune-release publish distrib
```

This means creating a Github release associated with the tag and upload the distribution tarball as a release artifact.

You can publish the documentation only with:

```
dune-release publish doc
```

This means publishing the dune generated documentation to `gh-pages` to be served as a static website on github.io.

If neither `distrib` neither `doc` is specified, `dune-release` publishes both:

```
dune-release publish
```

The full documentation of this command is available with
```
dune-release help publish
```

#### Publish troubleshooting

If github returns a `Permission denied` error during `dune-release publish`, the reason is probably a failing ssh connection. In that case, we suggest that you set up ssh. If you prefer not to and you've already set up https instead, we suggest that you configure git as follows:
```
git config [--global] url."https://github.com/".pushInsteadOf "git@github.com:"
```
Running that line once will configure git to always push over https - either for that repository or globally.

In more detail: `dune-release publish` always pushes to github over ssh by explicitly giving git the github uri of your project with ssh prefix (`git@github.com:`). By configuring git as suggested above, git will automatically replace that prefix by the https one when pushing and push over https instead.

### Create an opam package and submit it to the opam repository

To add the package to OCaml's [opam repository](https://github.com/ocaml/opam-repository), we start by creating an opam file to be used on the opam repository. This file includes the download URI for the distribution tarball and the tarball hash:

```
dune-release opam pkg
```

To submit the package to the opam repository and create the associated pull request we run:

```
dune-release opam submit
```

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

### Runtime dependencies

- `bzip2` can be set with the `DUNE_RELEASE_BZIP2` variable (deprecated), otherwise it is expected to be in `PATH`;
- `tar` can be set with the `DUNE_RELEASE_TAR` variable (deprecated), otherwise it is expected to be in `PATH`;
- `git` can be set with the `DUNE_RELEASE_GIT` variable (deprecated), otherwise it is expected to be in `PATH`;
- `hg` can be set with the `DUNE_RELEASE_HG` variable (deprecated), otherwise it is expected to be in `PATH`;
- `opam` can be set with the `HOST_OS_OPAM` variable (deprecated), otherwise it is looked for in `HOST_OS_XBIN/opam` (deprecated), otherwise it is looked for in `opamHOST_OS_SUFF` (deprecated), otherwise it is expected to be in `PATH`;
- `dune`, `curl`, `cp` and `ocamlfind` are expected to be in `PATH`.

Using these `DUNE_RELEASE_*` and `HOST_OS_*` environment variables to configure the path to these binaries is deprecated since `dune-release.1.4.0`, and will no longer be supported in `dune-release.2.0.0`, it is thus recommended to only rely on the `PATH` variable.
