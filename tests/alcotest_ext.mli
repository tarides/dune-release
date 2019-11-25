open Alcotest
open Bos_setup

val path : Fpath.t testable

val result_msg : 'a testable -> ('a, R.msg) result testable
