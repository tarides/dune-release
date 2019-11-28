let confirm_or_abort () =
  let has_been_executed = ref false in
  let check ~name ?skippable ~yes ~expected ~skippable_executed =
    has_been_executed := false;
    let actual =
      Dune_release.Prompt.confirm_or_abort ?skippable
        ~question:(fun l -> l "?")
        ~yes ()
    in
    Alcotest.(check (Alcotest_ext.result_msg unit)) name expected actual;
    Alcotest.(check bool) name skippable_executed !has_been_executed
  in
  (* cannot test when [~yes:false] because we would wait for user input *)
  check ~name:"1" ~yes:true ~expected:(Ok ()) ?skippable:None
    ~skippable_executed:false;
  check ~name:"2" ~yes:true ~expected:(Ok ()) ~skippable_executed:true
    ?skippable:
      (Some
         (fun () ->
           has_been_executed := true;
           Ok ()))

let suite = ("Prompt", [ ("confirm_or_abort", `Quick, confirm_or_abort) ])
