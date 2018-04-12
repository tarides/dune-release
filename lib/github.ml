(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup

(* Publish documentation *)

let repo_docdir_owner_repo_and_path_from_doc_uri uri =
  (* Parses the $PATH of $SCHEME://$HOST/$REPO/$PATH *)
  let uri_error uri =
    R.msgf "Could not derive publication directory $PATH from opam doc \
            field value %a; expected the pattern \
            $SCHEME://$OWNER.github.io/$REPO/$PATH" String.dump uri
  in
  match Text.split_uri ~rel:true uri with
  | None -> Error (uri_error uri)
  | Some (_, host, path) ->
      if path = "" then Error (uri_error uri) else
      (match String.cut ~sep:"." host with
      | Some (owner, g) when String.equal g "github.io" -> Ok owner
      | _ -> Error (uri_error uri))
      >>= fun owner ->
      match String.cut ~sep:"/" path with
      | None -> Error (uri_error uri)
      | Some (repo, "") -> Ok (owner, repo, Fpath.v ".")
      | Some (repo, path) ->
          (Fpath.of_string path >>| fun p -> owner, repo, Fpath.rem_empty_seg p)
          |> R.reword_error_msg (fun _ -> uri_error uri)

let publish_in_git_branch ~remote ~branch ~name ~version ~docdir ~dir =
  let pp_distrib ppf (name, version) =
    Fmt.pf ppf "%a %a" Text.Pp.name name Text.Pp.version version
  in
  let log_publish_result msg distrib dir =
    Logs.app (fun m -> m "%s %a@ in@ directory@ %a@ of@ gh-pages@ branch"
                 msg pp_distrib distrib Fpath.pp dir)
  in
  let cp src dst =
    let dst_is_root = Fpath.is_current_dir dst in
    let src =
      if dst_is_root then Fpath.to_dir_path src else Fpath.rem_empty_seg src
    in
    (* FIXME we lost Windows friends here, fix bos #30 *)
    OS.Cmd.run Cmd.(v "cp" % "-R" % p src % p dst)
  in
  let delete dir =
    if not (Fpath.is_current_dir dir) then OS.Dir.delete ~recurse:true dir else
    let delete acc p = acc >>= fun () -> OS.Path.delete ~recurse:true p in
    let gitdir = Fpath.v ".git" in
    let not_git p = not (Fpath.equal p gitdir) in
    OS.Dir.contents dir
    >>= fun files -> List.fold_left delete (Ok ()) (List.filter not_git files)
  in
  let git_for_repo r = Cmd.of_list (Cmd.to_list @@ Vcs.cmd r) in
  let replace_dir_and_push docdir dir =
    let msg = strf "Update %s doc to %s." name version in
    Vcs.get ()
    >>= fun repo -> Ok (git_for_repo repo)
    >>= fun git -> OS.Cmd.run Cmd.(git % "checkout" % branch)
    >>= fun () -> delete dir
    >>= fun () -> cp docdir dir
    >>= fun () -> Vcs.is_dirty repo
    >>= function
    | false -> Ok false
    | true ->
        OS.Cmd.run Cmd.(git % "add" % p dir)
        >>= fun () -> OS.Cmd.run Cmd.(git % "commit" % "-m" % msg)
        >>= fun () -> OS.Cmd.run Cmd.(git % "push")
        >>= fun () -> Ok true
  in
  if not (Fpath.is_rooted ~root:Fpath.(v ".") dir)
  then
    R.error_msgf "%a directory is not rooted in the repository or not relative"
      Fpath.pp dir
  else
  let clonedir = Fpath.(parent docdir / strf "%s-%s.pubdoc" name version) in
  OS.Dir.delete ~recurse:true clonedir
  >>= fun () -> Vcs.get ()
  >>= fun repo -> Vcs.clone repo ~dir:clonedir
  >>= fun () -> OS.Dir.with_current clonedir (replace_dir_and_push docdir) dir
  >>= fun res -> res
  >>= function
  | false (* no changes *) ->
      log_publish_result "No documentation changes for" (name, version) dir;
      Ok ()
  | true ->
      let push_spec = strf "%s:%s" branch branch in
      Ok (git_for_repo repo) >>= fun git ->
      OS.Cmd.run Cmd.(git % "push" % remote % push_spec)
      >>= fun () -> OS.Dir.delete ~recurse:true clonedir
      >>= fun () ->
      log_publish_result "Published documentation for" (name, version) dir;
      Ok ()

let uri p = Pkg.opam_field_hd p "doc" >>| function
  | None     -> ""
  | Some uri -> uri

let publish_doc p ~msg:_ ~docdir =
  uri p
  >>= fun uri -> Pkg.name p
  >>= fun name -> Pkg.version p
  >>= fun version -> repo_docdir_owner_repo_and_path_from_doc_uri uri
  >>= fun (owner, repo, dir) ->
  let remote = strf "git@@github.com:%s/%s.git" owner repo in
  let git_for_repo r = Cmd.of_list (Cmd.to_list @@ Vcs.cmd r) in
  let create_empty_gh_pages git =
    let msg = "Initial commit by topkg." in
    let create () =
      OS.Cmd.run Cmd.(v "git" % "init")
      >>= fun () -> Vcs.get ()
      >>= fun repo -> Ok (git_for_repo repo)
      >>= fun git -> OS.Cmd.run Cmd.(git % "checkout" % "--orphan" % "gh-pages")
      >>= fun () -> OS.File.write (Fpath.v "README") "" (* need some file *)
      >>= fun () -> OS.Cmd.run Cmd.(git % "add" % "README")
      >>= fun () -> OS.Cmd.run Cmd.(git % "commit" % "README" % "-m" % msg)
    in
    OS.Dir.with_tmp "gh-pages-%s.tmp" (fun dir () ->
        OS.Dir.with_current dir create () |> R.join
        >>= fun () -> OS.Cmd.run Cmd.(git % "fetch" % Fpath.to_string dir
                                      % "gh-pages")
      ) () |> R.join
  in
  Vcs.get ()
  >>= fun repo -> Ok (git_for_repo repo)
  >>= fun git ->
  (match OS.Cmd.run Cmd.(git % "fetch" % remote % "gh-pages") with
  | Ok () -> Ok ()
  | Error _ -> create_empty_gh_pages git)
  >>= fun () -> (OS.Cmd.run_out Cmd.(git % "rev-parse" % "FETCH_HEAD")
                 |> OS.Cmd.to_string)
  >>= fun id -> OS.Cmd.run Cmd.(git % "branch" % "-f" % "gh-pages" % id)
  >>= fun () ->
  publish_in_git_branch ~remote ~branch:"gh-pages" ~name ~version ~docdir ~dir

(* Publish releases *)

let repo_and_owner_of_uri uri =
  let uri_error uri =
    R.msgf "Could not derive owner and repo from opam dev-repo \
            field value %a; expected the pattern \
            $SCHEME://$HOST/$OWNER/$REPO[.$EXT][/$DIR]" String.dump uri
  in
  match Text.split_uri ~rel:true uri with
  | None -> Error (uri_error uri)
  | Some (_, _, path) ->
      if path = "" then Error (uri_error uri) else
      match String.cut ~sep:"/" path with
      | None -> Error (uri_error uri)
      | Some (owner, path) ->
          let repo = match String.cut ~sep:"/" path with
          | None -> path
          | Some (repo, _) -> repo
          in
          begin
            Fpath.of_string repo
            >>= fun repo -> Ok (owner, Fpath.(to_string @@ rem_ext repo))
          end
          |> R.reword_error_msg (fun _ -> uri_error uri)

let steal_opam_publish_github_auth () =
  let opam = Cmd.(v "opam") in
  let publish = Fpath.v "plugins/opam-publish" in
  OS.Cmd.exists opam >>= function
  | false -> Ok None
  | true ->
      OS.Cmd.(run_out Cmd.(opam % "config" % "var" % "root") |> to_string)
      >>= fun root -> Fpath.of_string root
      >>= fun root -> OS.Path.query Fpath.(root // publish / "$(user).token")
      >>= function
      | [] -> Ok None
      | (file, defs) :: _ ->
          OS.File.read file >>= fun token ->
          Ok (Some (strf "%s:%s" (String.Map.get "user" defs) token))

let github_auth ~owner =
  match
    steal_opam_publish_github_auth ()
    |> Logs.on_error_msg ~use:(fun _ -> None)
  with
  | Some auth -> auth
  | None -> OS.Env.(value "TOPKG_GITHUB_AUTH" string ~absent:owner)

let create_release_json version msg =
  let escape_for_json s =
    let len = String.length s in
    let max = len - 1 in
    let rec escaped_len i l =
      if i > max then l else
      match String.get s i with
      | '\\' | '\"' | '\n' | '\r' | '\t' -> escaped_len (i + 1) (l + 2)
      | _  -> escaped_len (i + 1) (l + 1)
    in
    let escaped_len = escaped_len 0 0 in
    if escaped_len = len then s else
    let b = Bytes.create escaped_len in
    let rec loop i k =
      if i > max then Bytes.unsafe_to_string b else
      match String.get s i with
      | ('\\' | '\"' | '\n' | '\r' | '\t' as c) ->
          Bytes.set b k '\\';
          let c = match c with
          | '\\' -> '\\' | '\"' -> '\"' | '\n' -> 'n' | '\r' -> 'r'
          | '\t' -> 't'
          | _ -> assert false
          in
          Bytes.set b (k + 1) c; loop (i + 1) (k + 2)
      | c ->
          Bytes.set b k c; loop (i + 1) (k + 1)
    in
    loop 0 0
  in
  strf "{ \"tag_name\" : \"%s\", \
          \"body\" : \"%s\" }" (escape_for_json version) (escape_for_json msg)

let run_with_auth auth curl =
    let auth = strf "-u %s" auth in
    OS.Cmd.(in_string auth |> run_io curl)

let curl_create_release curl version msg owner repo =
  let parse_release_id resp = (* FIXME this is retired. *)
    let headers = String.cuts ~sep:"\r\n" resp in
    try
      let not_slash c = not (Char.equal '/' c) in
      let loc = List.find (String.is_prefix ~affix:"Location:") headers in
      let id = String.take ~rev:true ~sat:not_slash loc in
      match String.to_int id with
      | None -> R.error_msgf "Could not parse id from location header %S" loc
      | Some id -> Ok id
    with Not_found ->
      R.error_msgf "Could not find release id in response:\n%s."
        (String.concat ~sep:"\n" headers)
  in
  let data = create_release_json version msg in
  let uri = strf "https://api.github.com/repos/%s/%s/releases" owner repo in
  let auth = github_auth ~owner in
  let cmd = Cmd.(curl % "-D" % "-" % "--data" % data % uri) in
  run_with_auth auth cmd |> OS.Cmd.to_string ~trim:false
  >>= parse_release_id

let curl_upload_archive curl archive owner repo release_id =
  let uri =
      (* FIXME upload URI prefix should be taken from release creation
         response *)
      strf "https://uploads.github.com/repos/%s/%s/releases/%d/assets?name=%s"
        owner repo release_id (Fpath.filename archive)
  in
  let auth = github_auth ~owner in
  let data = Cmd.(v "--data-binary" % strf "@@%s" (Fpath.to_string archive)) in
  let ctype = Cmd.(v "-H" % "Content-Type:application/x-tar") in
  let cmd = Cmd.(curl %% ctype %% data % uri) in
  OS.Cmd.(run_with_auth auth cmd |> to_stdout)

let publish_distrib p ~msg ~archive =
  let git_for_repo r = Cmd.of_list (Cmd.to_list @@ Vcs.cmd r) in
  uri p
  >>= fun uri -> Pkg.version p
  >>= fun version -> OS.Cmd.must_exist Cmd.(v "curl" % "-s" % "-S" % "-K" % "-")
  >>= fun curl -> Vcs.get ()
  >>= fun repo -> Ok (git_for_repo repo)
  >>= fun git -> OS.Cmd.run Cmd.(git % "push" % "--force" % "--tags")
  >>= fun () -> repo_and_owner_of_uri uri
  >>= fun (owner, repo) -> curl_create_release curl version msg owner repo
  >>= fun id -> curl_upload_archive curl archive owner repo id


(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli

   Permission to use, copy, modify, and/or distribute this software for any
   purpose with or without fee is hereby granted, provided that the above
   copyright notice and this permission notice appear in all copies.

   THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
   WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
   MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
   ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
   WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
   ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
   OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
  ---------------------------------------------------------------------------*)
