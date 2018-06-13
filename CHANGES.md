## dev

- Default to `nano` if the EDITOR environment variable is not set.

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
