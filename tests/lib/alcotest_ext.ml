open Alcotest

let path = testable Fpath.pp Fpath.equal

let error_msg =
  testable Bos_setup.R.pp_msg (fun (`Msg e1) (`Msg e2) -> String.equal e1 e2)

let result_msg testable = result testable error_msg

let opam_version =
  testable Dune_release.Opam.Version.pp Dune_release.Opam.Version.equal

let curl =
  let pp fs Dune_release.Curl.{ url; args } =
    let args = Dune_release.Curl_option.to_string_list args in
    Format.fprintf fs "url = %S;@ " url;
    Format.fprintf fs "args = %a@\n" (Fmt.list ~sep:Fmt.sp Fmt.string) args
  in
  testable pp ( = )

let homepage_uri = testable Dune_release.Github_uri.Homepage.pp ( = )

let repo_uri = testable Dune_release.Github_uri.Repo.pp ( = )

let doc_uri = testable Dune_release.Github_uri.Doc.pp ( = )

let distrib_uri = testable Dune_release.Github_uri.Distrib.pp ( = )
