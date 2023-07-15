open Caretaker

let test_same_field () =
  let x = "da56149b:Build system" in
  let y = "build system" in
  Alcotest.(check bool) __LOC__ true (Fields.same x y)

let tests = ("fields", [ Alcotest.test_case "same" `Quick test_same_field ])
