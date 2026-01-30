(** Gitattributes tests.

    - Archive integration: tests that Archive.tar excludes files matching
      export-ignore patterns
    - Pattern matching: compares our implementation against git check-attr as
      source of truth, with .gitattributes content generated from test cases *)

open Dune_release

(*===========================================================================
 * Archive integration
 *)

(** Test archive creation with export-ignore patterns. This tests the full
    integration without requiring git. *)
let test_archive_export_ignore () =
  let ( >>= ) = Result.bind in
  let result =
    Bos.OS.Dir.tmp "archive-test-%s" >>= fun dir ->
    (* Create test file structure *)
    let files =
      [
        ("CHANGES.md", "changes");
        ("foo.opam", "opam");
        ("dune-project", "(lang dune 3.0)");
        ("dune-workspace", "(lang dune 3.0)");
        ( ".gitattributes",
          "dune-workspace export-ignore\n\
           .github/** export-ignore\n\
           internal/** export-ignore" );
        (".github/workflows/ci.yml", "ci");
        ("internal/notes.txt", "notes");
        ("src/main.ml", "let () = ()");
      ]
    in
    let create_file (path, content) =
      let fpath = Fpath.(dir // v path) in
      let parent = Fpath.parent fpath in
      Bos.OS.Dir.create ~path:true parent >>= fun _ ->
      Bos.OS.File.write fpath content
    in
    List.fold_left
      (fun acc file -> acc >>= fun () -> create_file file)
      (Ok ()) files
    >>= fun () ->
    (* Read export-ignore patterns *)
    Gitattributes.read_export_ignore dir >>= fun export_ignore ->
    (* Create the archive *)
    let exclude_paths = Fpath.Set.empty in
    let root = Fpath.v "test-1.0.0" in
    let mtime = 0L in
    Archive.tar dir ~exclude_paths ~export_ignore ~root ~mtime
    >>= fun tar_content ->
    (* Write tarball and list contents *)
    let tarball = Fpath.(dir / "test.tar") in
    Bos.OS.File.write tarball tar_content >>= fun () ->
    let cmd = Bos.Cmd.(v "tar" % "-tf" % Fpath.to_string tarball) in
    Bos.OS.Cmd.(run_out cmd |> out_lines) >>= fun (files_in_tar, _) ->
    Ok files_in_tar
  in
  match result with
  | Error (`Msg msg) -> Alcotest.fail msg
  | Ok files_in_tar ->
      let has_file name =
        List.exists
          (fun f -> Astring.String.is_infix ~affix:name f)
          files_in_tar
      in
      (* Check that excluded files are NOT present *)
      Alcotest.(check bool)
        "dune-workspace excluded" false
        (has_file "dune-workspace");
      Alcotest.(check bool) ".github excluded" false (has_file ".github");
      Alcotest.(check bool) "internal excluded" false (has_file "internal");
      (* Check that included files ARE present *)
      Alcotest.(check bool) "CHANGES.md included" true (has_file "CHANGES.md");
      Alcotest.(check bool) "foo.opam included" true (has_file "foo.opam");
      Alcotest.(check bool)
        ".gitattributes included" true
        (has_file ".gitattributes");
      Alcotest.(check bool) "src/main.ml included" true (has_file "src/main.ml")

let archive_tests =
  [ ("archive with export-ignore", `Quick, test_archive_export_ignore) ]

(*===========================================================================
 * Pattern matching
 *)

(** Build mapping from pattern to unique prefix. *)
let pattern_prefix_map pattern_tests =
  let patterns =
    pattern_tests |> List.map fst |> List.sort_uniq String.compare
  in
  List.mapi (fun i p -> (p, Printf.sprintf "t%03d" (i + 1))) patterns

(** Generate .gitattributes content from test cases. *)
let generate_gitattributes parse_tests pattern_tests =
  let buf = Buffer.create 4096 in
  (* Add parse test lines *)
  List.iter
    (fun (line, _) ->
      Buffer.add_string buf line;
      Buffer.add_char buf '\n')
    parse_tests;
  Buffer.add_char buf '\n';
  (* Add pattern test lines with prefix *)
  let prefix_map = pattern_prefix_map pattern_tests in
  List.iter
    (fun (pattern, prefix) ->
      Printf.bprintf buf "%s/%s export-ignore\n" prefix pattern)
    prefix_map;
  Buffer.contents buf

(** Generate all test paths. *)
let generate_test_paths parse_tests pattern_tests =
  let prefix_map = pattern_prefix_map pattern_tests in
  (* Parse test paths *)
  let parse_paths = List.map snd parse_tests in
  (* Pattern test paths with prefix *)
  let pattern_paths =
    List.map
      (fun (pattern, path) ->
        let prefix = List.assoc pattern prefix_map in
        prefix ^ "/" ^ path)
      pattern_tests
  in
  parse_paths @ pattern_paths

let setup_git_repo gitattributes_content =
  match Bos.OS.Dir.tmp "gitattributes-test-%s" with
  | Error _ -> None
  | Ok dir -> (
      let cmd =
        Bos.Cmd.(v "git" % "-C" % Fpath.to_string dir % "init" % "-q")
      in
      match Bos.OS.Cmd.run cmd with
      | Error _ -> None
      | Ok () -> (
          (* Write the .gitattributes file *)
          let gitattributes = Fpath.(dir / ".gitattributes") in
          match Bos.OS.File.write gitattributes gitattributes_content with
          | Error _ -> None
          | Ok () -> Some dir))

let run_git_check_attr ~dir ~path =
  let cmd =
    Bos.Cmd.(
      v "git" % "-C" % Fpath.to_string dir % "check-attr" % "export-ignore"
      % path)
  in
  match Bos.OS.Cmd.(run_out cmd |> out_string) with
  | Error _ -> None
  | Ok (output, _) -> Some (Astring.String.is_infix ~affix:": set" output)

let git_tests gitattributes_content test_paths =
  match setup_git_repo gitattributes_content with
  | None -> [] (* Skip git tests if git setup fails *)
  | Some dir ->
      List.map
        (fun path ->
          let name = Printf.sprintf "git: %s" path in
          let test_fun () =
            match run_git_check_attr ~dir ~path with
            | None -> Alcotest.fail "Could not run git check-attr"
            | Some git_result ->
                let patterns =
                  Gitattributes.parse_export_ignore gitattributes_content
                in
                let our_result =
                  List.exists (Gitattributes.matches (Fpath.v path)) patterns
                in
                Alcotest.(check bool) name git_result our_result
          in
          (name, `Quick, test_fun))
        test_paths

(** Pattern matching test cases: (pattern, path) pairs. Each pattern gets a
    unique prefix (t001/, t002/, etc.) to isolate tests. *)
let pattern_tests =
  [
    (* Basic glob patterns *)
    ("*.log", "debug.log");
    ("*.log", "subdir/debug.log");
    ("*.log", "a/b/c/debug.log");
    ("*.log", "foo.txt");
    (* Exact basename matching *)
    ("dune-workspace", "dune-workspace");
    ("dune-workspace", "subdir/dune-workspace");
    ("dune-workspace", "other-file");
    (* Directory patterns with /** *)
    (".github/**", ".github");
    (".github/**", ".github/workflows");
    (".github/**", ".github/workflows/ci.yml");
    (".github/**", ".github-actions");
    (".github/**", "src/main.ml");
    (* Glob prefix with /** *)
    ("test_*/**", "test_foo/bar.ml");
    ("test_*/**", "test_foo/sub/file.ml");
    ("test_*/**", "other/file.ml");
    (* **/ in middle of pattern *)
    ("src/**/test.ml", "src/test.ml");
    ("src/**/test.ml", "src/foo/test.ml");
    ("src/**/test.ml", "src/foo/bar/test.ml");
    ("src/**/test.ml", "test.ml");
    (* **/ at start *)
    ("**/build", "build");
    ("**/build", "foo/build");
    ("**/build", "foo/bar/build");
    ("**/build", "builder");
    (* Directory wildcard *)
    ("dir/*.log", "dir/foo.log");
    ("dir/*.log", "dir/sub/foo.log");
    ("dir/*.log", "other/foo.log");
    (* Star not crossing slash *)
    ("a*b", "aXXXb");
    ("a*b", "a/b");
    (* Question mark *)
    ("file?.txt", "file1.txt");
    ("file?.txt", "file12.txt");
    (* Double star alone *)
    ("**", "anything");
    ("**", "a/b/c");
    (* Single star *)
    ("*", "foo");
    ("*", "foo/bar");
    (* **/f pattern - matches f at any level *)
    ("**/f", "f");
    ("**/f", "a/f");
    ("**/f", "a/b/f");
    ("**/f", "a/b/c/f");
    ("**/f", "g");
    ("**/f", "fx");
    (* a**f pattern - ** without slash acts like * *)
    ("a**f", "af");
    ("a**f", "axf");
    ("a**f", "axxf");
    ("a**f", "a/f");
    ("a**f", "a/b/f");
    (* Simple basename patterns matching at multiple levels *)
    ("f", "f");
    ("f", "a/f");
    ("f", "a/b/f");
    ("f", "g");
    ("f", "fx");
    (* Path-specific patterns *)
    ("a/f", "a/f");
    ("a/f", "b/a/f");
    (* Path-specific pattern should not match when nested deeper *)
    ("a/i", "a/i");
    ("a/i", "subdir/a/i");
    ("a/b/g", "a/b/g");
    ("b/g", "b/g");
    ("b/g", "a/b/g");
    (* Path normalization - git normalizes paths before matching *)
    ("f", "./f");
    ("a/g", "a/./g");
    ("a/b/g", "a/c/../b/g");
    (* Exact path matching *)
    ("subdir/file", "subdir/file");
    ("a/b", "x/a/b");
    ("src/file.ml", "root/src/file.ml");
    (* Leading slash stripped *)
    ("/dune-workspace", "dune-workspace");
    (* Literal dot in pattern *)
    ("file.txt", "file.txt");
    ("file.txt", "filextxt");
    (* Case sensitivity *)
    ("Makefile", "Makefile");
    (* Prefix no false positive nested *)
    (".git/**", ".github/workflows/ci.yml");
    (* Star alone with extension *)
    ("*", "foo.ml");
    (* Star not matching slash *)
    ("a*.ml", "a/foo.ml");
    (* Question mark not matching slash *)
    ("a?b", "a/b");
    (* Trailing slash patterns - trailing slashes are not stripped, so these
       patterns won't match paths without trailing slashes *)
    ("dir/", "dir");
    ("*/", "dir");
    (* Double star not adjacent to slash *)
    ("a**b", "aXXXb");
    ("a**b", "a/x/b");
    (* Double star at start without slash *)
    ("**test.ml", "test.ml");
    ("**test.ml", "src/test.ml");
    (* */** pattern *)
    ("*/**", "foo/bar");
    ("*/**", "foo/bar/baz.txt");
    (* **/ pattern alone *)
    ("**/", "foo/");
    ("**/", "foo");
    (* **/** pattern *)
    ("**/**", "foo/bar");
    ("**/**", "a/b/c/d");
    ("**/**", "foo");
    (* Mixed * and ? *)
    ("*.?", "foo.c");
    ("*.?", "foo.ml");
    ("?est_*", "test_foo");
    ("t?st_*.ml", "test_foo.ml");
    (* Empty/whitespace patterns - these become empty string after trim and
       never match anything *)
    ("", "foo");
    ("   ", "foo");
  ]

(** Parsing edge cases: (gitattributes_line, test_path). Lines are written
    exactly as-is to .gitattributes. *)
let parse_tests =
  [
    (* UTF-8 BOM at start of file - must be first to test BOM handling *)
    ("\xef\xbb\xbfparse_bom export-ignore", "parse_bom");
    (* Comment handling *)
    ("# comment line\nparse_comment export-ignore", "parse_comment");
    (* Empty line handling *)
    ( "parse_before export-ignore\n\nparse_after_empty export-ignore",
      "parse_after_empty" );
    (* Tab as separator *)
    ("parse_tab\texport-ignore", "parse_tab");
    (* Multiple attributes - export-ignore second *)
    ("parse_multi_second binary export-ignore", "parse_multi_second");
    (* Multiple attributes - export-ignore first *)
    ("parse_multi_first export-ignore text", "parse_multi_first");
    (* No export-ignore attribute - should NOT match *)
    ("parse_no_export binary", "parse_no_export");
    (* Attribute as substring - should NOT match *)
    ("parse_substr not-export-ignore-really", "parse_substr");
    (* Attribute as prefix - should NOT match *)
    ("parse_attr_prefix export-ignore-extended", "parse_attr_prefix");
    (* Attribute as suffix - should NOT match *)
    ("parse_attr_suffix my-export-ignore", "parse_attr_suffix");
    (* Leading whitespace on pattern *)
    ("  parse_whitespace  export-ignore", "parse_whitespace");
    (* Hash in pattern (not a comment) *)
    ("parse#hash export-ignore", "parse#hash");
    (* Pattern with no attributes - should NOT match *)
    ("parse_no_attr", "parse_no_attr");
    (* Indented comment *)
    ( "  # indented comment\nparse_indented_comment export-ignore",
      "parse_indented_comment" );
    (* Whitespace-only line *)
    ( "parse_ws_before export-ignore\n   \t  \nparse_ws_after export-ignore",
      "parse_ws_after" );
    (* Windows line endings *)
    ("parse_crlf export-ignore\r\nparse_crlf2 export-ignore", "parse_crlf2");
  ]

let gitattributes_content = generate_gitattributes parse_tests pattern_tests
let test_paths = generate_test_paths parse_tests pattern_tests

let suite =
  ("Gitattributes", archive_tests @ git_tests gitattributes_content test_paths)
