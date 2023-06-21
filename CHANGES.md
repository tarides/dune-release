## unreleased

### Added

### Changed

- Running `dune-release check` now attempts to discover and parse the change
  log, and a new flag `--skip-change-log` disables this behaviour. (#458,
  @gridbugs)
- List the main package and amount of subpackages when creating the PR to avoid
  very long package lists in PRs (#465, @emillon)

### Deprecated

### Fixed

- Avoid collision between branch and tag name. Tag detection got confused when
  branch was named the same as tag. Now it searches only for tag refs, instead
  of all refs. (#452, @3Rafal)

- Fix project name detection from `dune-project`. The parser could get confused
  when opam file generation is used. Now it only considers the first `(name X)`
  in the file. (#445, @emillon)

### Removed

- Remove support for delegates.
  Previous users of this feature should now use `dune-release delegate-info`
  and wrap dune-release calls in a script. See #188 for details.
  (#428, @NathanReb)
- Removed support for the OPAM 1.2.2 client. This means `dune-release` expects
  the `opam` binary to be version 2.0 at least. (#406, #411,
  @Leonidas-from-XIV)

### Security

## 1.6.1

### Fixed

- Fix compatibility with Cmdliner 1.1.0. This also unfortunately means that the
  minimum OCaml version is 4.08 now. (#429, @NathanReb)

## 1.6.0

### Added

- Add `--skip-lint`, `--skip-build`, `--skip-test` and
  `--keep-build-dir` to the main command (#419, @NathanReb)
- Added support for parsing changelogs written in the style of
  [keepachangelog.com](https://keepachangelog.com/) (#421, @ifazk)

## 1.5.2

### Fixed

- Fixed the release asset URL for projects with multiple opam packages. Before,
  the packages would attempt to infer their URL and fail in rare cases where
  the project uses `v` as prefix for tags but the project version omits it. Now
  they share the same URL. (#402, #404, @Leonidas-from-XIV)

## 1.5.1

### Added

- Added support for creating releases from unannotated Git tags. `dune-release`
  supported unannotated tags in a few places already, now it supports using
  them for creating a release. (#383, @Leonidas-from-XIV)

### Fixed

- Change the `---V` command option to be `-V` (#388, @Leonidas-from-XIV)
- Infer release versions are inferred from VCS tags. This change allows using
  `dune-release` on projects that do not use the changelog or have it in a
  different format.  (#381, #383 @Leonidas-from-XIV)
- Fix a bug where `dune-release` couldn't retrieve a release on GitHub if the
  tag and project version don't match (e.g. `v1.0` vs `1.0`). `dune-release`
  would in such case believe the release doesn't exist, attempt to create it
  and subsequently fail. (#387, #395, @Leonidas-from-XIV)

## 1.5.0 (2021-07-05)

### Added

- Add `--no-auto-open` to the default command. It was previously only available for
  `dune-release opam`. (#374, @NathanReb)
- Add a `config create` subcommand to create a fresh configuration if you don't have one yet
  (#373, @NathanReb)
- Add `--local-repo`, `--remote-repo` and `--opam-repo` options to the default command,
  they used to be only available for the `opam` subcommand (#363, @NathanReb)
- Add a `--token` option to `dune-release publish` and `dune-release opam` commands
  to specify a github token. This allows dune-release to be called through a Github
  Actions workflow and use the github token through an environment variable.
  (#284 #368, @gpetiot @NathanReb)
- Log curl calls on verbose/debug mode (#281, @gpetiot)
- Try to publish the release asset again after it failed (#272, @gpetiot)
- Improve error reporting of failing git comands (#257, @gpetiot)
- Suggest a solution for users without ssh setup (#304, @pitag-ha)
- Allow including git submodules to the distrib tarball by passing the
  `--include-submodules` flag to `dune-release`, `dune-release bistro` or
  `dune-release distrib` (#300, @NathanReb)
- Support 'git://' scheme for dev-repo uri (#331, @gpetiot)
- Support creation of draft releases and draft PRs. Define a new option
  `--draft` for `dune-release publish` and `dune-release opam submit` commands.
  (#248, @gpetiot)
- Add a new command `check` to check the prerequisites of dune-release and
  avoid starting a release process that couldn't be finished (#318, #351, @pitag-ha)
- When preparing the opam-repository PR and pushing the local branch to 
  the user's remote opam-repository fork, use `--set-upstream` to ease any further
  update of the PR (#350, @gpetiot)

### Changed

- Entirely rely on the remote fork of opam-repository URL in `opam submit` instead of
  reading the user separately. The information was redundant and could only lead to bugs
  when unproperly set. (#372, @NathanReb)
- Use pure token authentication for Github API requests rather than "token as passwords"
  authentication (#369, @NathanReb)
- Require tokens earlier in the execution of commands that use the github API. If the token
  isn't saved to the user's configuration, the prompt for creating one will show up at the
  command startup rather than on sending the first request (#368, @NathanReb)
- Attach the changelog to the annotated tag message (#283, @gpetiot)
- Do not remove versioned files from the tarball anymore. We used to exclude
  `.gitignore`, `.gitattributes` and other such files from the archive.
  (#299, @NathanReb)
- Don't try to push the tag if it is already present and point to the same ref on the remote.
  `dune-release` must guess which URI to pass to `git push` and may guess it wrong.
  This change allows users to push the tag manually to avoid using that code. (#219, @Julow)
- Don't try to create the release if it is already present and points to the same tag (#277, @kit-ty-kate)
- Recursively exclude all `.git`/`.hg` files and folders from the distrib
  tarball (#300, @NathanReb)
- Make the automatic dune-release workflow to stop if a step exits with a non-zero code (#332, @gpetiot)
- Make git-related mdx tests more robust in unusual environments (#334, @sternenseemann)
- Set the default tag message to "Release <tag>" instead of "Distribution <tag>"
- Opam file linter: check for `synopsis` instead of `description` (#291, @kit-ty-kate)
- Upgrade the use of the opam libraries to opam 2.1 (#343, @kit-ty-kate)

### Deprecated

- Deprecate the `--user` CLI options and configuration field, they were redundant with
  the remote-repo option and field and could be set unproperly, leading to bugs (#372, @NathanReb)
- Deprecate the use of delegates in `dune-release publish` (#276, #302, @pitag-ha)
- Deprecate the use of opam file format 1.x (#352, @NathanReb)

### Removed

- Option --name is removed from all commands. When used with
  `dune-release distrib`, it was previously effectively ignored. Now
  it is required to add a `(name <name>)` stanza to
  `dune-project`. (#327, @lehy)

### Fixed

- Fix a bug where `opam submit` would look up a config file, even though all the required
  information was provided on the command line. This would lead to starting the interactive
  config creation quizz if that file did not exist which made it impossible to use it in a CI
  for instance. (#373, @NathanReb)
- Fix a bug where `opam submit` would fail on non-github repositories if the user had no
  configuration file (#372, @NathanReb)
- Fix a bug where subcommands wouldn't properly read the token files, leading to authentication
  failures on API requests (#368, @NathanReb)
- Fix a bug in `opam submit` preventing non-github users to create the opam-repo PR
  via dune-release. (#359, @NathanReb)
- Fix a bug where `opam submit` would try to parse the custom URI provided through
  `--distrib-uri` as a github repo URI instead of using the dev-repo (#358, @NathanReb)
- Fix the priority of the `--distrib-uri` option in `dune-release opam pkg`.
  It used to have lower precedence than the url file written by `dune-release publish`
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
- Better report GitHub API errors, all of the error messages reported by the GitHub API are now checked and reported to the user. (#290, @gpetiot)
- Fix error message when `dune-release tag` cannot guess the project name (#319, @lehy)
- Always warn about uncommitted changes at the start of `dune-release
  distrib` (#325, @lehy).  Otherwise uncommitted changes to
  dune-project would be silently ignored by `dune-release distrib`.
- Fix rewriting of github references in changelog (#330, @gpetiot)
- Fixes a bug under cygwin where dune-release was unable to find the commit hash corresponding to the release tag (#329, @gpetiot)
- Fixes release names by explicitly setting it to match the released version (#338, @NathanReb)
- Fix a bug that prevented release of a package whose version number contains invalid characters for a git branch. The git branch names are now sanitized. (#271, @gpetiot)
- `publish`: Fix the process of inferring user name and repo from the dev repo uri (#348, @pitag-ha)

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
- Fix a bug where opam files could be improperly tempered with while building
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
- Do not read/need a `pkg/pkg.ml` file.
