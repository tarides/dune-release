open Rresult
open Dune_release

let fpath = Alcotest.testable Fpath.pp Fpath.equal

let run f =
  match f with
  | Error (`Msg e) -> Alcotest.failf "Got an error: %s" e
  | Ok x -> x

let check f ?version ?tag ?keep_v ?opam ~cat ~name expected =
  let test () =
    run
      ( ( match opam with
        | None -> Ok None
        | Some lines ->
            let file = Fpath.(v "opam-tmp") in
            let lines = ("opam-version", "1.2") :: lines in
            let lines = List.map (fun (k, v) -> Fmt.strf "%s: %S" k v) lines in
            Bos.OS.File.write_lines file lines >>| fun () -> Some file )
      >>= fun opam ->
        let p = Pkg.v ~dry_run:false ~name ?tag ?version ?keep_v ?opam () in
        let n = Fmt.strf "check %S" expected in
        f p >>| fun actual -> Alcotest.(check fpath) n Fpath.(v expected) actual
      )
  in
  (cat, `Quick, test)

let distrib_file =
  let check =
    check ~cat:"distrib_file" ~name:"foo" Pkg.(distrib_file ~dry_run:true)
  in
  [
    check ~tag:"v0" "_build/foo-v0.tbz";
    check ~version:"v0" "_build/foo-v0.tbz";
    check ~tag:"v0" ~keep_v:false "_build/foo-v0.tbz";
    check ~tag:"v0" ~keep_v:true "_build/foo-v0.tbz";
    check ~tag:"v0" ~version:"x" "_build/foo-v0.tbz";
  ]

let distrib_filename =
  let cat = "distrib_filename" in
  let check_true = check ~cat ~name:"foo" Pkg.(distrib_filename ~opam:true) in
  let check_false = check ~cat ~name:"foo" Pkg.(distrib_filename ~opam:false) in
  [
    check_false ~tag:"v0" "foo-v0";
    check_true ~tag:"v0" "foo.0";
    check_false ~version:"v0" "foo-v0";
    check_true ~version:"v0" "foo.v0";
    check_false ~tag:"v0" ~keep_v:false "foo-v0";
    check_true ~tag:"v0" ~keep_v:false "foo.0";
    check_false ~tag:"v0" ~keep_v:true "foo-v0";
    check_true ~tag:"v0" ~keep_v:true "foo.v0";
    check_false ~tag:"v0" ~version:"x" "foo-v0";
    check_true ~tag:"v0" ~version:"x" "foo.x";
  ]

let distrib_uri =
  let cat = "distrib_uri" in
  let check = check ~cat ~name:"yo" (fun x -> Pkg.distrib_uri x >>| Fpath.v) in
  let dev_repo = [ ("dev-repo", "git@github.com:foo/bar.git") ] in
  let homepage = [ ("homepage", "https://github.com/foo/bar") ] in
  let url = "https://github.com/foo/bar/releases/download/v0/yo-v0.tbz" in
  [
    check ~opam:dev_repo ~tag:"v0" url;
    check ~opam:homepage ~tag:"v0" url;
    check ~opam:dev_repo ~version:"v0" url;
    check ~opam:homepage ~version:"v0" url;
    check ~opam:dev_repo ~tag:"v0" ~keep_v:false url;
    check ~opam:homepage ~tag:"v0" ~keep_v:true url;
    check ~opam:dev_repo ~tag:"v0" ~version:"x" url;
    check ~opam:homepage ~tag:"v0" ~version:"x" url;
    check ~opam:[ ("homepage", "https://foo.github.io/bar") ] ~tag:"v0" url;
  ]

let suite = ("tags", distrib_file @ distrib_filename @ distrib_uri)
