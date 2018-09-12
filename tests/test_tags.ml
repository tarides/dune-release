open Rresult
open Dune_release

let fpath = Alcotest.testable Fpath.pp Fpath.equal

let run f = match f with
| Error (`Msg e) -> Alcotest.failf "Got an error: %s" e
| Ok x -> x

let check f ?version ?tag ?keep_v ?opam ~name x =
  run (
    begin match opam with
    | None       -> Ok None
    | Some lines ->
        let file = Fpath.(v "opam-tmp") in
        let lines = ("opam-version",  "1.2") :: lines in
        let lines = List.map (fun (k, v) -> Fmt.strf "%s: %S" k v) lines in
        Bos.OS.File.write_lines file lines >>| fun () ->
        Some file
    end >>= fun opam ->
    let p = Pkg.v ~dry_run:false ~name ?tag ?version ?keep_v ?opam () in
    let n = Fmt.strf "check %S" x in
    f p >>| fun f ->
    Alcotest.(check fpath) n f Fpath.(v x)
  )

let distrib_file () =
  let check = check ~name:"foo" Pkg.(distrib_file ~dry_run:true) in
  check ~tag:"v0"               "_build/foo-v0.tbz";
  check ~version:"v0"           "_build/foo-v0.tbz";
  check ~tag:"v0" ~keep_v:false "_build/foo-v0.tbz";
  check ~tag:"v0" ~keep_v:true  "_build/foo-v0.tbz";
  check ~tag:"v0" ~version:"x"  "_build/foo-v0.tbz"

let distrib_filename () =
  let check_true = check ~name:"foo" Pkg.(distrib_filename ~opam:true) in
  let check_false = check ~name:"foo" Pkg.(distrib_filename ~opam:false) in
  check_false ~tag:"v0"               "foo-v0";
  check_true  ~tag:"v0"               "foo.0" ;
  check_false ~version:"v0"           "foo-v0";
  check_true  ~version:"v0"           "foo.v0";
  check_false ~tag:"v0" ~keep_v:false "foo-v0";
  check_true  ~tag:"v0" ~keep_v:false "foo.0" ;
  check_false ~tag:"v0" ~keep_v:true  "foo-v0";
  check_true  ~tag:"v0" ~keep_v:true  "foo.v0";
  check_false ~tag:"v0" ~version:"x"  "foo-v0";
  check_true  ~tag:"v0" ~version:"x"  "foo.x"

let distrib_uri () =
  let check = check ~name:"foo" (fun x -> Pkg.distrib_uri x >>| Fpath.v) in
  let dev_repo = ["dev-repo", "git@github.com:foo/bar.git"] in
  let homepage = ["homepage", "https://github.com/foo/bar"] in
  check ~opam:dev_repo ~tag:"v0"
    "https://github.com/foo/bar/releases/download/v0/foo-v0.tbz";
  check ~opam:homepage ~tag:"v0"
    "https://github.com/foo/bar/releases/download/v0/foo-v0.tbz";
  check ~opam:dev_repo ~version:"v0"
    "https://github.com/foo/bar/releases/download/v0/foo-v0.tbz";
  check ~opam:homepage ~version:"v0"
    "https://github.com/foo/bar/releases/download/v0/foo-v0.tbz";
  check ~opam:dev_repo ~tag:"v0" ~keep_v:false
    "https://github.com/foo/bar/releases/download/v0/foo-v0.tbz";
  check ~opam:homepage ~tag:"v0" ~keep_v:true
    "https://github.com/foo/bar/releases/download/v0/foo-v0.tbz";
  check ~opam:dev_repo ~tag:"v0" ~version:"x"
    "https://github.com/foo/bar/releases/download/v0/foo-v0.tbz";
  check ~opam:homepage ~tag:"v0" ~version:"x"
    "https://github.com/foo/bar/releases/download/v0/foo-v0.tbz"

let suite: unit Alcotest.test = "tags", [
  "distrib_file"    , `Quick, distrib_file;
  "distrib_filename", `Quick, distrib_filename;
  "distrib_uri"     , `Quick, distrib_uri;
]
