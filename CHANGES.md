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
