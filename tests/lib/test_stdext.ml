let is_backup_file () =
  let check ~input ~expected =
    let name = "Path.is_backup_file " ^ input in
    let actual = Dune_release.Stdext.Path.is_backup_file input in
    Alcotest.(check bool) name expected actual
  in
  check ~input:"" ~expected:false;
  check ~input:"fooooooooooooo" ~expected:false;
  check ~input:"fooooooooo#" ~expected:false;
  check ~input:"#fooooooooo#" ~expected:true;
  check ~input:"foooooooooooo~" ~expected:true

let find_files () =
  let check ~name ~paths ~names_wo_ext ~expected =
    let paths = List.map Fpath.v paths in
    let expected = List.map Fpath.v expected in
    let actual = Dune_release.Stdext.Path.find_files ~names_wo_ext paths in
    let open Alcotest in
    let open Alcotest_ext in
    (check (list path)) name expected actual
  in
  check ~name:"Path.find_files no alternative" ~names_wo_ext:[]
    ~paths:[ "foo"; ".foo"; "foo~" ] ~expected:[];
  check ~name:"Path.find_files empty" ~paths:[] ~names_wo_ext:[ "" ]
    ~expected:[];
  check ~name:"Path.find_files does not contain" ~names_wo_ext:[ "foo" ]
    ~paths:[ "aaa"; "bbb"; "#foo#"; "foo~"; ".foo.md.swp" ]
    ~expected:[];
  check ~name:"Path.find_files contains" ~names_wo_ext:[ "foo" ]
    ~paths:[ "aaa"; "bbb"; "#foo#"; "foo~"; ".foo.md.swp"; "foo"; "foo.ml" ]
    ~expected:[ "foo"; "foo.ml" ]

let suite =
  ( "Stdext",
    [
      ("Path.is_backup_file", `Quick, is_backup_file);
      ("Path.find_files", `Quick, find_files);
    ] )
