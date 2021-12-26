let ch = Dune_release.Version.Changelog.of_string

let test_change_log_last_entry =
  let make_test ~name ~input ~expected =
    let name = "change_log_last_entry " ^ name in
    let test_fun () =
      let changelog_version = Alcotest_ext.changelog_version in
      Alcotest.(check (option (pair changelog_version (pair string string))))
        name expected
        (Dune_release.Text.change_log_last_entry input)
    in
    (name, `Quick, test_fun)
  in
  [
    make_test ~name:"empty" ~input:"" ~expected:None;
    make_test ~name:"change list 0"
      ~input:{|
# v0.1
  - change A  
  - change B  
|}
      ~expected:(Some (ch "v0.1", ("# v0.1", "  - change A\n  - change B")));
    make_test ~name:"change list 1"
      ~input:{|
# v0.1

  - change A
  - change B
|}
      ~expected:(Some (ch "v0.1", ("# v0.1", "  - change A\n  - change B")));
    make_test ~name:"change list 2"
      ~input:{|
# v0.1


  - change A
  - change B
|}
      ~expected:(Some (ch "v0.1", ("# v0.1", "\n  - change A\n  - change B")));
    make_test ~name:"many entries"
      ~input:{|
# v0.1

change A

# v0.0.1

change B
|}
      ~expected:(Some (ch "v0.1", ("# v0.1", "change A")));
    make_test ~name:"keepachangelog.com 1"
      ~input:
        {|
# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2021-12-26
### Added
- Added 3
- Added 2

### Changed
- Changed 1

### Removed
- Removed 1

## [0.3.0] - 2021-12-03
### Added
- Added 1
|}
      ~expected:(Some (ch "Unreleased", ("## [Unreleased]", "")));
    make_test ~name:"keepachangelog.com 2"
      ~input:
        {|
# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2021-12-26
### Added
- Added 3
- Added 2

### Changed
- Changed 1

### Removed
- Removed 1

## [0.3.0] - 2021-12-03
### Added
- Added 1
|}
      ~expected:
        (Some
           ( ch "1.0.0",
             ( "## [1.0.0] - 2021-12-26",
               "### Added\n\
                - Added 3\n\
                - Added 2\n\n\
                ### Changed\n\
                - Changed 1\n\n\
                ### Removed\n\
                - Removed 1" ) ));
  ]

let test_rewrite_github_refs =
  let user = "user" and repo = "repo" in
  let make_test name (input, expected) =
    let name = "rewrite_github_refs " ^ name in
    let test_fun () =
      Alcotest.(check string)
        name expected
        (Dune_release.Text.rewrite_github_refs ~user ~repo input)
    in
    (name, `Quick, test_fun)
  in
  [
    make_test "rewritten 0" ("... #123 ...", "... user/repo#123 ...");
    make_test "rewritten 1" ("... (#123 ...", "... (user/repo#123 ...");
    make_test "not rewritten 0" ("... xyz#123 ...", "... xyz#123 ...");
    make_test "not rewritten 1" ("... (xyz#123 ...", "... (xyz#123 ...");
    make_test "not rewritten 2" ("... xy0#123 ...", "... xy0#123 ...");
    make_test "not rewritten 3" ("... (xy0#123 ...", "... (xy0#123 ...");
  ]

let suite = ("Text", test_change_log_last_entry @ test_rewrite_github_refs)
