open Alcotest
open Bos_setup

val path : Fpath.t testable

val result_msg : 'a testable -> ('a, R.msg) result testable

val opam_version : Dune_release.Opam.Version.t testable

val curl : Dune_release.Curl.t testable

val homepage_uri : Dune_release.Github_uri.Homepage.t testable

val repo_uri : Dune_release.Github_uri.Repo.t testable

val doc_uri : Dune_release.Github_uri.Doc.t testable

val distrib_uri : Dune_release.Github_uri.Distrib.t testable
