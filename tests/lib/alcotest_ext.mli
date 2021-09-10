open Alcotest
open Bos_setup

val path : Fpath.t testable

val result_msg : 'a testable -> ('a, R.msg) result testable

val tag : Dune_release.Vcs.Tag.t testable

val opam_version : Dune_release.Opam.Version.t testable

val curl : Dune_release.Curl.t testable
