let test_version_line_re =
  let make_test ~input ~expected =
    let test_name =
      if expected then
        input ^ "is a valid version field line"
      else
        input ^ "is not a valid version field line"
    in
    let test_fun () =
      let re = Re.compile Dune_release.Pkg.version_line_re in
      let actual = Re.execp re input in
      Alcotest.(check bool) test_name expected actual
    in
    (test_name, `Quick, test_fun)
  in
  [ make_test ~input:"" ~expected:false
  ; make_test ~input:{|version:""|} ~expected:false
  ; make_test ~input:{|version:"1"|} ~expected:true
  ; make_test ~input:{|version:     "1"    |} ~expected:true
  ; make_test ~input:{|version:"1.jfpojef.adp921709"|} ~expected:true
  ]

let test_prepare_opam_for_distrib =
  let make_test ~name ~version ~content ~expected () =
    let test_name = "prepare_opam_for_distrib: " ^ name in
    let test_fun () =
      let actual = Dune_release.Pkg.prepare_opam_for_distrib ~version ~content in
      Alcotest.(check (list string)) test_name expected actual
    in
    (test_name, `Quick, test_fun)
  in
  [ make_test ~name:"empty" ~content:[] ~version:"1" ~expected:[{|version: "1"|}] ()
  ; make_test
      ~name:"replace version"
      ~content:[{|version: "1"|}]
      ~version:"2"
      ~expected:[{|version: "2"|}]
      ()
  ; make_test
      ~name:"only replace version field"
      ~content:
        [ {|version: "1"|}
        ; {|description: """|}
        ; {|version: "1" blablabla|}
        ; {|"""|}
        ]
      ~version:"2"
      ~expected:
        [ {|version: "2"|}
        ; {|description: """|}
        ; {|version: "1" blablabla|}
        ; {|"""|}
        ]
      ()
  ]

let suite =
  ("Pkg", test_version_line_re @ test_prepare_opam_for_distrib)
