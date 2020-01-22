let confirm_or_abort_or_skip () =
  let has_been_executed = ref false in
  let check ~name ~f ~yes ~expected ~skippable_executed =
    has_been_executed := false;
    let actual =
      Dune_release.Prompt.confirm_or_abort_or_skip ~f
        ~question:(fun l -> l "?")
        ~yes
    in
    Alcotest.(check (Alcotest_ext.result_msg unit)) name expected actual;
    Alcotest.(check bool) name skippable_executed !has_been_executed
  in
  (* cannot test when [~yes:false] because we would wait for user input *)
  check ~name:"choose yes" ~yes:true ~expected:(Ok ()) ~skippable_executed:true
    ~f:(fun () ->
      has_been_executed := true;
      Ok ())

let suite =
  ("Prompt", [ ("confirm_or_abort_or_skip", `Quick, confirm_or_abort_or_skip) ])
