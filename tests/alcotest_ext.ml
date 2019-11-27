open Alcotest

let path = testable Fpath.pp Fpath.equal

let error_msg =
  testable Bos_setup.R.pp_msg (fun (`Msg e1) (`Msg e2) -> String.equal e1 e2)

let result_msg testable = result testable error_msg
