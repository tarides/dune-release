## unreleased

### Added

- Add a `--token` option to `dune-release publish` and `dune-release opam` commands to specify a github token. This allows dune-release to be called through a Github Actions workflow and use the github token through an environment variable. (#284, @gpetiot)
- Log curl calls on verbose/debug mode (#281, @gpetiot)
- Try to publish the release asset again after it failed (#272, @gpetiot)
- Improve error reporting of failing git comands (#257, @gpetiot)

### Changed

- Attach the changelog to the annotated tag message (#283, @gpetiot)
- Deprecate the use of delegates in `dune-release publish` (#276, @pitag-ha)
- Do not remove versioned files from the tarball anymore. We used to exclude
  `.gitignore`, `.gitattributes` and other such files from the archive.
  (#299, @NathanReb)

### Deprecated

### Removed

### Fixed

- Fix the priority of the `--distrib-uri` option in `dune-release opam pkg`.
  It used to have lower precendence than the url file written by `dune-release publish`
  and therefore made it impossible to overwrite it if needed. (#255, @NathanReb)
- Fix a bug with --distrib-file in `dune-release opam pkg` where you would need
  the regular dune-release generated archive to be around even though you specified
  a custom distrib archive file. (#255, @NathanReb)
- Use int64 for timestamps. (#261, @gpetiot)
- Define the order of packages (#263, @gpetiot)
- Allow the dry-run mode to continue even after some API call's response were expected by using placeholder values (#262, @gpetiot)
- Build and run tests for all selected packages when checking distribution tarball
  (#266, @NathanReb)
- Improve trimming of the changelog to preserve the indentation of the list of changes. (#268, @gpetiot)
- Trim the data of the `url` file before filling the `url.src` field. This fixes an issue that caused the `url.src` field to be a multi-line string instead of single line. (#270, @gpetiot)
- Fix a bug causing dune-release to exclude all hidden files and folders (starting with `.`) at the
  repository from the distrib archive (#298, @NathanReb)

### Security

## 1.4.0 (2020-07-13)

### Added

- Add a `dune-release config` subcommand to display and edit the global
  configuration (#220, @NathanReb).
- Add command `delegate-info` to print information needed by external
  release scripts (#221, @pitag-ha)
- Use Curly instead of Cmd to interact with github (#202, @gpetiot)
- Add `x-commit-hash` field to the opam file when releasing (#224, @gpetiot)
- Add support for common alternative names for the license and
  ChangeLog file (#204, @paurkedal)

### Changed

- Command `tag`: improve error and log messages by comparing the provided
  commit with the commit correspondent to the provided tag (#226, @pitag-ha)
- Error logs: when an external command fails, include its error message in
  the error message posted by `dune-release` (#231, @pitag-ha)
- Error log formatting: avoid unnecessary line-breaks; indent only slightly
  in multi-lines (#234, @pitag-ha)
- Linting step of `dune-release distrib` does not fail when opam's `doc` field
  is missing. Do not try to generate nor publish the documentation when opam's
  `doc` field is missing. (#235, @gpetiot)

### Deprecated

- Deprecate opam 1.x (#195, @gpetiot)

### Fixed

- Separate packages names by spaces in `publish` logs (#171, @hannesm)
- Fix uncaught exceptions in distrib subcommand and replace them with proper
  error messages (#176, @gpetiot)
- Use the 'user' field in the configuration before inferring it from repo URI
  and handles HTTPS URIs (#183, @gpetiot)
- Ignore backup files when looking for README, CHANGES and LICENSE files
  (#194, @gpetiot)
- Do not echo input characters when reading token (#199, @gpetiot)
- Improve the output of VCS command errors (#193, @gpetiot)
- Better error handling when checking opam version (#195, @gpetiot)
- Do not write 'version' and 'name' fields in opam file (#200, @gpetiot)
- Use Yojson to parse github json response and avoid parsing bugs.
  (#177, @gpetiot)
- The `git` command used in `publish doc` should check `DUNE_RELEASE_GIT` (even
  if deprecated) before `PATH`. (#242, @gpetiot)
- Adapt the docs to the removal of the `log` subcommand (#196, @gpetiot)

### Removed

### Security

## 1.3.3 (2019-09-30)

### Fixed

- Fix a bug where `opam submit` would fail if the opam files had no description
  (#165, @NathanReb)
- Fix a bug where opam files could be inproperly tempered with while building
  the distribution tarball (#168, @NathanReb)

## 1.3.2 (2019-07-12)

### Fixed

- Fix a bug where file presence lint check wouldn't be run for `CHANGES`,
  `LICENSE` and `README` (#161, @NathanReb)

### Changed

- Add headers to better distinguish various `dune-release` logs such as user
  prompts and informational logs

## 1.3.1 (2019-06-11)

- Fix a bug in documentation publication where under certain circumstances the
  doc would be published in a `_html` folder instead of being published at the
  root of `gh-pages` (#157, @NathanReb)

## 1.3.0 (2019-05-29)

- Add confirmation prompts in some commands. (#144, #146, @NathanReb)
- Use github returned archive URL instead of guessing it. Fixes a bug
  when releasing a version with URL incompatible characters to github.
  (#143, @NathanReb)
- Add logs to better describe commands behaviour. (#141, #137, #135, #150,
  #153, @NathanReb)
- Fix a bug when publishing documentation to a repo for the first time
  (#136, @NathanReb)
- Allow to submit package to a different opam-repository hosted on github.
  (#140, #152, @NathanReb)
- Use `dune subst` for watermarking. (#147, @NathanReb)
- Fix linting step so it checks for `CHANGES`, `LICENSE` and `README` again

## 1.2.0 (2019-04-08)

- Remove assert false in favor of error message. (#125, @ejgallego)
- Embed a 'version: "$release-version"' in each opam file of the current
  directory to get reproducible releases (#128, #129, @hannesm)
- Generate sha256 and sha512 checksums for release (#131, @hannesm)
- Grammar fixes (#132, @anmonteiro)
- Handle doc fields with no trailing slash (#133, @yomimono)

## 1.1.0 (2018-10-17)

- Remove the status and log commands (#95, @samoht)
- Fix `dune-release publish doc` when using multiple packages (#96, @samoht)
- Fix inferred package name when reading `dune-project` files (#104. @samoht)
- Add .ps and .eps files to default files excluded from watermarking
  (backport of dbuenzli/topkg@6cf1eae)
- Fix distribution uri when homepage is using github.io (#102, @samoht)
- `dune-release lint` now checks that a description and a synopsis exist
  in opam2 files (#101, @samoht)
- Add a more explicit error message if `git checkout` fails in the local
  opam-repository (#98, @samoht)
- Do not create an extra `_html` folder when publishing docs on Linux
  (#94, @anuragsoni and @samoht)

## 1.0.1 (2018-09-24)

- Fix opam2 format upgrade when submitting a PR (#91, @samoht)

## 1.0.0 (2018-09-23)

- Determine opam-repository fork user from URI (#64, @NathanReb and @diml)
- All subcommands now support multiple package names (@samoht)
- Do not remove `Makefile` from the distribution archives (#71, @samoht)
- Do not duplicate version strings in opam file (#72, @samoht)
- Fix configuration file upgrade from 0.2 (#55, @samoht)
- Add a `--tag` option to select the release tag (@samoht)
- Add a `--version` option to select the release version (@samoht)
- Fix `--keep-v` (#70, @samoht)
- Make `dune-release <OPTIONS>` a shorchut to  `dune-release bistro <OPTIONS>`
  (#75, @samoht)
- Add a --no-open option to not open a browser after creating a new P
  (#79, @samoht)
- Control `--keep-v` and `--no-auto-open` via options in the config file
  (#79, @samoht)
- Be flexible with file names (#86 and #20, @anuragsoni)

## 0.3.0 (2018-07-10)

- Store config files in `~/.config/dune/` instead of `~/.dune`
  to match what `dune` is doing (#27, @samoht)
- Support opam 1.2.2 when linting (#29, @samoht)
- Use `-p <pkg>` instead of `-n <pkg>` to follow dune convention
  (#30, #42, @samoht)
- Default to `nano` if the EDITOR environment variable is not set. (#32, @avsm)
- Fix location of documentation when `odoc` creates an `_html` subdirectory
  (#34, @samoht)
- Remove the browse command (#36, @samoht)
- Re-add the publish delegatation mechanism to allow non-GitHub users to
  publish packages (see `dune-release help delegate`) (#37, @samoht)
- Fix dropping of `v` at the beginning of version numbers in `dune-release opam`
  (#40, @let-def)
- Add basic token validation (#40, @let-def)

## 0.2.0 (2018-06-08)

- Remove opam lint warnings for 1.2 files (#2, @samoht)
- Add a `--keep-v` option to not drop `v` at the beginning of version
  numbers (#6, @samoht)
- Pass `-p <package>` to jbuilder (#8, @diml)
- Fix a bug in `Distrib.write_subst` which could cause an infinite loop
  (#10, @diml)
- Add a `--dry-run` option to avoid side-effects for all commands (@samoht)
- Rewrite issues numbers in changelog to point to the right repository
  (#13, @samoht)
- Stop force pushing tags to `origin`. Instead, just force push the release
  tag directly to the `dev-repo` repository (@samoht)
- Fix publishing distribution when the the tag to publish is not the repository
  HEAD (#4, @samoht)
- Do not depend on `opam-publish` anymore. Use configuration files stored
  in `~/.dune` to parametrise the publishing workflow. (@samoht)

## 0.1.0 (2018-04-12)

Initial release.

Import some code from [topkg](http://erratique.ch/software/topkg).

- Use of `Astring`, `Logs`, `Fpath` and`Bos` instead of custom
  re-implementations;
- Remove the IPC layer which is used between `topkg` and `topkg-care`;
- Bundle everything as a single binary;
- Assume that the package is built using [dune](https://github.com/ocaml/dune);
- Do not read/neeed a `pkg/pkg.ml` file.
