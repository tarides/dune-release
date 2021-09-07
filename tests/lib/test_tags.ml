open Rresult
open Dune_release

let make_test f ?version ?tag ?keep_v ?opam ~cat ~name expected =
  let open Alcotest_ext in
  let test () =
    let n = Fmt.strf "check %S" expected in
    let expected = Ok (Fpath.v expected) in
    let actual =
      (match opam with
      | None -> Ok None
      | Some lines ->
          let file = Fpath.(v "opam-tmp") in
          let lines = ("opam-version", "1.2") :: lines in
          let lines = List.map (fun (k, v) -> Fmt.strf "%s: %S" k v) lines in
          Bos.OS.File.write_lines file lines >>| fun () -> Some file)
      >>= fun opam ->
      let p = Pkg.v ~dry_run:false ~name ?tag ?version ?keep_v ?opam () in
      f p
    in
    Alcotest.(check (result_msg path)) n expected actual
  in
  (cat, `Quick, test)

let distrib_file =
  let make_test ~test_name =
    let cat = "distrib_file: " ^ test_name in
    make_test ~cat ~name:"foo" Pkg.(distrib_file ~dry_run:true)
  in
  [
    make_test ~test_name:"tag" ~tag:"v0" "_build/foo-v0.tbz";
    make_test ~test_name:"version" ~version:"v0" "_build/foo-v0.tbz";
    make_test ~test_name:"tag without v" ~tag:"v0" ~keep_v:false
      "_build/foo-v0.tbz";
    make_test ~test_name:"tag with v" ~tag:"v0" ~keep_v:true "_build/foo-v0.tbz";
    make_test ~test_name:"tag and version" ~tag:"v0" ~version:"x"
      "_build/foo-v0.tbz";
  ]

let distrib_filename =
  let make_test ~test_name ~opam =
    let cat = "distrib_filename: " ^ test_name in
    make_test ~cat ~name:"foo" (Pkg.distrib_filename ~opam)
  in
  [
    make_test ~test_name:"1" ~opam:false ~tag:"v0" "foo-v0";
    make_test ~test_name:"2" ~opam:true ~tag:"v0" "foo.0";
    make_test ~test_name:"3" ~opam:false ~version:"v0" "foo-v0";
    make_test ~test_name:"4" ~opam:true ~version:"v0" "foo.v0";
    make_test ~test_name:"5" ~opam:false ~tag:"v0" ~keep_v:false "foo-v0";
    make_test ~test_name:"6" ~opam:true ~tag:"v0" ~keep_v:false "foo.0";
    make_test ~test_name:"7" ~opam:false ~tag:"v0" ~keep_v:true "foo-v0";
    make_test ~test_name:"8" ~opam:true ~tag:"v0" ~keep_v:true "foo.v0";
    make_test ~test_name:"9" ~opam:false ~tag:"v0" ~version:"x" "foo-v0";
    make_test ~test_name:"10" ~opam:true ~tag:"v0" ~version:"x" "foo.x";
  ]

let distrib_uri =
  let make_test ~test_name =
    let cat = "distrib_uri:" ^ test_name in
    make_test ~cat ~name:"yo" (fun x ->
        Pkg.infer_github_distrib_uri x >>| Fpath.v)
  in
  let dev_repo = [ ("dev-repo", "git@github.com:foo/bar.git") ] in
  let homepage = [ ("homepage", "https://github.com/foo/bar") ] in
  let url = "https://github.com/foo/bar/releases/download/v0/yo-v0.tbz" in
  [
    make_test ~test_name:"1" ~opam:dev_repo ~tag:"v0" url;
    make_test ~test_name:"2" ~opam:homepage ~tag:"v0" url;
    make_test ~test_name:"3" ~opam:dev_repo ~version:"v0" url;
    make_test ~test_name:"4" ~opam:homepage ~version:"v0" url;
    make_test ~test_name:"5" ~opam:dev_repo ~tag:"v0" ~keep_v:false url;
    make_test ~test_name:"6" ~opam:homepage ~tag:"v0" ~keep_v:true url;
    make_test ~test_name:"7" ~opam:dev_repo ~tag:"v0" ~version:"x" url;
    make_test ~test_name:"8" ~opam:homepage ~tag:"v0" ~version:"x" url;
    make_test ~test_name:"9"
      ~opam:[ ("homepage", "https://foo.github.io/bar") ]
      ~tag:"v0" url;
  ]

let suite = ("tags", distrib_file @ distrib_filename @ distrib_uri)
