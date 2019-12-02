open Alcotest

let path = testable Fpath.pp Fpath.equal

let error_msg =
  testable Bos_setup.R.pp_msg (fun (`Msg e1) (`Msg e2) -> String.equal e1 e2)

let result_msg testable = result testable error_msg

let opam_version =
  testable Dune_release.Opam.Version.pp Dune_release.Opam.Version.equal
