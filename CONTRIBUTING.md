## Setting up your working environment

If you want to contribute to the project you'll first need to install the dependencies.
You can do it via `opam`:

```sh
$ git clone git@github.com:tarides/dune-release.git
$ cd dune-release
$ opam switch create ./ ocaml-base-compiler.4.14.0 --deps-only -t --with-dev-setup
```

This will create a local switch with a fresh compiler, the dependencies of
`dune-release` and the dependencies for running the tests. The exact OCaml
version is just an example, you should be able to use any reasonably recent
version of OCaml.

From there you can build `dune-release` by simply running:

```sh
$ dune build
```

and run the test suite with:

```sh
$ dune runtest
```

## Tests

In a effort to cover as much of the codebase with tests as possible, new contributions
should come with tests when possible/it makes sense.

dune-release uses [dune's cram
tests](https://dune.readthedocs.io/en/stable/tests.html#cram-tests) extensively
to make sure the workflows work as expected and don't break for our users.

### Unit testing

We should aim at improving the unit tests coverage as much as possible. Our
unit tests can be found in [`tests/lib/`](tests/lib). They are written using
the [alcotest](https://github.com/mirage/alcotest) testing framework. If you
want to add new tests, we encourage you to reuse the style used in the existing
tests ([`test_vcs.ml`](tests/lib/test_vcs.ml) is a good example).

There should be one test module per actual module there. The test runner is
[`tests.ml`](tests/lib/tests.ml). If you add tests for a new or so far untested
module, don't forget to add its test suite to the runner.

For each function we test, we build a list of Alcotest `unit test_case`. It's
important to try to be consistent in that regard as it makes the output of the
test runner more readable and helps with fixing or investigating broken tests.

For each module, we then have one Alcotest `unit test` that contains the
concatenation of all the test cases.

That results in the following test output for a successful run:

```sh
$ dune runtest
       tests alias tests/lib/runtest
Testing `dune-release'.
This run has ID `14602E98-BFF4-4D74-A50A-56466A3F2C5B'.

  [OK]          Github                 0   Parse.ssh_uri_from_http https://gi...
  ...
  [OK]          Github_repo           15   from_gh_pages: https://user.github...

Full test results in `.../_build/default/tests/lib/_build/_tests/dune-release'.
Test Successful in 0.017s. 95 tests run.
```

### End-to-end testing

End-to-end tests directly call the `dune-release` binary and make sure it
behaves in the expected way. They live in the [`tests/bin/`](tests/bin)
directory.

We have one folder there per aspect we want to test, for instance the tests for
determining the version from a tag live in
[`version-from-tag/`](tests/bin/version-from-tag).

Make sure to only output relevant information in your test by e.g.
postprocessing the output with `grep` and the usual POSIX tools. This makes the
test more relevant, easier to read and less fragile should other things change.

If these tools don't suffice/are not portable there is an OCaml helper binary
[`tests/bin/helpers/make_dune_release_deterministic`](tests/bin/helpers/make_dune_release_deterministic.ml)
that can be extended to make the output more deterministic and can be used to
filter output in the `cram` tests.

If your tests change behavior but the change is correct you can use `dune
promote` to update your test file so the next run of `dune runtest` will expect
the new behavior.

## Code formatting

Submitted code should be formatted using the supplied ocamlformat config. To do
so easily use dune's [automated
formatting](https://dune.readthedocs.io/en/stable/formatting.html#formatting-a-project):

```sh
$ dune fmt
```

This will automatically reformat all source files to fit the configuation.

When submitting a PR, the CI will check for formatting, so if the formatting is
wrong it will issue an error.

## Changelog

User-visible changes should come with an entry in the [changelog](CHANGES.md)
under the appropriate part of the **unreleased** section. They should describe
the change from the point of view of a user and include the PR number and
username of the contributor. Check the existing entries for reference.

The PR number is only known at submit time, so the placeholder `#<PR_NUMBER>`
can be used, which will then trigger a bot to suggest the right number of the
PR when submitting.

When submitting a PR the PR check require an entry, although for changes that
are not user-visible this can be overridden using the "no changelog" label.
