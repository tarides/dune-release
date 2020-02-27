(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup

module D = struct
  let user = "${user}"

  let repo = "${repo}"

  let dir = Fpath.v "${dir}"

  let fetch_head = "${fetch_head}"
end

module Parse = struct
  let user_from_regexp_opt uri regexp =
    try Some Re.(Group.get (exec (Emacs.compile_pat regexp) uri) 1)
    with Not_found -> None

  let user_from_remote uri =
    match uri with
    | _ when Bos_setup.String.is_prefix uri ~affix:"git@" ->
        user_from_regexp_opt uri "git@github\\.com:\\(.+\\)/.+\\(\\.git\\)?"
    | _ when Bos_setup.String.is_prefix uri ~affix:"https://" ->
        user_from_regexp_opt uri "https://github\\.com/\\(.+\\)/.+\\(\\.git\\)?"
    | _ -> None

  let archive_upload_url response =
    let open Re in
    let re =
      seq
        [
          str "\"browser_download_url\":";
          rep space;
          char '"';
          group (non_greedy (rep any));
          char '"';
        ]
    in
    let compiled = compile re in
    let error () =
      R.error_msgf "Could not extract archive url from:\n %s" response
    in
    match exec_opt compiled response with
    | Some groups when Group.test groups 1 -> Ok (Group.get groups 1)
    | Some _ | None -> error ()
end

(* Publish documentation *)

let publish_in_git_branch ~dry_run ~remote ~branch ~name ~version ~docdir ~dir
    ~yes =
  let pp_distrib ppf (name, version) =
    Fmt.pf ppf "%a %a" Text.Pp.name name Text.Pp.version version
  in
  let log_publish_result msg distrib dir =
    App_log.success (fun m ->
        m "%s %a in directory %a of gh-pages branch" msg pp_distrib distrib
          Fpath.pp dir)
  in
  let delete dir =
    if not (Fpath.is_current_dir dir) then Sos.delete_dir ~dry_run dir
    else
      let delete acc p = acc >>= fun () -> Sos.delete_path ~dry_run p in
      let gitdir = Fpath.v ".git" in
      let not_git p = not (Fpath.equal p gitdir) in
      OS.Dir.contents dir >>= fun files ->
      List.fold_left delete (Ok ()) (List.filter not_git files)
  in
  let git_for_repo r = Cmd.of_list (Cmd.to_list @@ Vcs.cmd r) in
  let replace_dir_and_push docdir dir =
    let msg = strf "Update %s doc to %s." name version in
    Vcs.get () >>= fun repo ->
    Ok (git_for_repo repo) >>= fun git ->
    Sos.run_quiet ~dry_run ~force:(dir <> D.dir) Cmd.(git % "checkout" % branch)
    >>= fun () ->
    delete dir >>= fun () ->
    Sos.cp ~dry_run ~rec_:true ~force:true ~src:Fpath.(docdir / ".") ~dst:dir
    >>= fun () ->
    (if dry_run then Ok true else Vcs.is_dirty repo) >>= function
    | false -> Ok false
    | true ->
        Sos.run ~dry_run Cmd.(git % "add" % p dir) >>= fun () ->
        Sos.run_quiet ~dry_run Cmd.(git % "commit" % "-m" % msg) >>= fun () ->
        Sos.run_quiet ~dry_run Cmd.(git % "push") >>= fun () -> Ok true
  in
  if not (Fpath.is_rooted ~root:Fpath.(v ".") dir) then
    R.error_msgf "%a directory is not rooted in the repository or not relative"
      Fpath.pp dir
  else
    let clonedir = Fpath.(parent (parent (parent docdir)) / "gh-pages") in
    Sos.delete_dir ~dry_run ~force:true clonedir >>= fun () ->
    Vcs.get () >>= fun repo ->
    Vcs.clone ~dry_run ~force:true ~dir:clonedir repo >>= fun () ->
    Sos.relativize ~src:clonedir ~dst:docdir >>= fun rel_docdir ->
    App_log.status (fun l ->
        l "Updating local %a branch" Text.Pp.commit "gh-pages");
    Sos.with_dir ~dry_run clonedir (replace_dir_and_push rel_docdir) dir
    >>= fun res ->
    res >>= function
    | false (* no changes *) ->
        log_publish_result "No documentation changes for" (name, version) dir;
        Ok ()
    | true ->
        let push_spec = strf "%s:%s" branch branch in
        Ok (git_for_repo repo) >>= fun git ->
        Prompt.confirm_or_abort ~yes ~question:(fun l ->
            l "Push new documentation to %a?" Text.Pp.url (remote ^ "#gh-pages"))
        >>= fun () ->
        App_log.status (fun l ->
            l "Pushing new documentation to %a" Text.Pp.url
              (remote ^ "#gh-pages"));
        Sos.run_quiet ~dry_run Cmd.(git % "push" % remote % push_spec)
        >>= fun () ->
        Sos.delete_dir ~dry_run clonedir >>= fun () ->
        log_publish_result "Published documentation for" (name, version) dir;
        Ok ()

let publish_doc ~dry_run ~msg:_ ~docdir ~yes p =
  (if dry_run then Ok D.(user, repo, dir) else Pkg.doc_user_repo_and_path p)
  >>= fun (user, repo, dir) ->
  Pkg.name p >>= fun name ->
  Pkg.version p >>= fun version ->
  let remote = strf "git@@github.com:%s/%s.git" user repo in
  let git_for_repo r = Cmd.of_list (Cmd.to_list @@ Vcs.cmd r) in
  let force = user <> D.user in
  let create_empty_gh_pages git =
    let msg = "Initial commit by dune-release." in
    let create () =
      Sos.run_quiet ~dry_run Cmd.(v "git" % "init") >>= fun () ->
      Vcs.get () >>= fun repo ->
      Ok (git_for_repo repo) >>= fun git ->
      Sos.run_quiet ~dry_run Cmd.(git % "checkout" % "--orphan" % "gh-pages")
      >>= fun () ->
      Sos.write_file ~dry_run (Fpath.v "README") ""
      (* need some file *) >>= fun () ->
      Sos.run_quiet ~dry_run Cmd.(git % "add" % "README") >>= fun () ->
      Sos.run_quiet ~dry_run Cmd.(git % "commit" % "README" % "-m" % msg)
    in
    OS.Dir.with_tmp "gh-pages-%s.tmp"
      (fun dir () ->
        Sos.with_dir ~dry_run dir create () |> R.join >>= fun () ->
        let git_fetch =
          Cmd.(git % "fetch" % Fpath.to_string dir % "gh-pages")
        in
        Sos.run_quiet ~dry_run ~force git_fetch)
      ()
    |> R.join
  in
  Vcs.get () >>= fun vcs ->
  Ok (git_for_repo vcs) >>= fun git ->
  let git_fetch = Cmd.(git % "fetch" % remote % "gh-pages") in
  ( match Sos.run_quiet ~dry_run ~force git_fetch with
  | Ok () -> Ok ()
  | Error _ ->
      App_log.status (fun l ->
          l "Creating new gh-pages branch with inital commit on %s/%s" user repo);
      create_empty_gh_pages git )
  >>= fun () ->
  Sos.run_out ~dry_run ~force
    Cmd.(git % "rev-parse" % "FETCH_HEAD")
    ~default:D.fetch_head OS.Cmd.to_string
  >>= fun id ->
  Sos.run_quiet ~dry_run ~force Cmd.(git % "branch" % "-f" % "gh-pages" % id)
  >>= fun () ->
  publish_in_git_branch ~dry_run ~remote ~branch:"gh-pages" ~name ~version
    ~docdir ~dir ~yes

(* Publish releases *)

let github_auth ~dry_run ~user token =
  Sos.read_file ~dry_run token >>= fun token -> Ok (strf "%s:%s" user token)

let run_with_auth ~dry_run auth curl k =
  let auth = strf "-u %s" auth in
  Sos.run_io ~dry_run curl (OS.Cmd.in_string auth) k

let curl_create_release ~token ~dry_run curl version msg user repo =
  let parse_release_id resp =
    (* FIXME this is retired. *)
    let headers = String.cuts ~sep:"\r\n" resp in
    try
      let not_slash c = not (Char.equal '/' c) in
      let loc = List.find (String.is_prefix ~affix:"Location:") headers in
      let id = String.take ~rev:true ~sat:not_slash loc in
      match String.to_int id with
      | Some id -> Ok id
      | None ->
          R.error_msgf "Could not parse id from location header %S: %S" loc id
    with Not_found ->
      R.error_msgf "Could not find release id in response:\n%s."
        (String.concat ~sep:"\n" headers)
  in
  github_auth ~dry_run ~user token >>= fun auth ->
  let args = Curl.create_release ~version ~msg ~user ~repo in
  let cmd = List.fold_left Cmd.( % ) curl args in
  run_with_auth ~dry_run ~default:"Location: /0" auth cmd
    (OS.Cmd.to_string ~trim:false)
  >>= parse_release_id

let curl_upload_archive ~token ~dry_run curl archive user repo release_id =
  let args = Curl.upload_archive ~archive ~user ~repo ~release_id in
  github_auth ~dry_run ~user token >>= fun auth ->
  let cmd = List.fold_left Cmd.( % ) curl args in
  run_with_auth ~dry_run ~default:"No response" auth cmd
    (OS.Cmd.to_string ~trim:false)

let curl_open_pr ~token ~dry_run ~title ~distrib_user ~user ~branch ~body
    ~opam_repo curl =
  let parse_url resp =
    (* FIXME this is nuts. *)
    let url =
      Re.(
        compile
        @@ seq
             [
               bol;
               str {|  "html_url":|};
               rep space;
               char '"';
               group (rep (compl [ char '"' ]));
             ])
    in
    let alread_exists = Re.(compile @@ str "A pull request already exists") in
    try Ok (`Url Re.(Group.get (exec url resp) 1))
    with Not_found ->
      if Re.execp alread_exists resp then Ok `Already_exists
      else R.error_msgf "Could not find html_url id in response:\n%s." resp
  in
  let args = Curl.open_pr ~title ~user ~branch ~body ~opam_repo in
  let cmd = List.fold_left Cmd.( % ) curl args in
  github_auth ~dry_run ~user:distrib_user token >>= fun auth ->
  let default = {|  "html_url": "${pr_url}",|} in
  run_with_auth ~dry_run ~default auth cmd (OS.Cmd.to_string ~trim:false)
  >>= parse_url

let open_pr ~token ~dry_run ~title ~distrib_user ~user ~branch ~opam_repo body =
  OS.Cmd.must_exist Cmd.(v "curl" % "-s" % "-S" % "-K" % "-") >>= fun curl ->
  curl_open_pr ~token ~dry_run ~title ~distrib_user ~user ~branch ~body
    ~opam_repo curl

let dev_repo p =
  Pkg.dev_repo p >>= function
  | Some r -> Ok r
  | None ->
      Pkg.opam p >>= fun opam ->
      R.error_msgf "The field dev-repo is missing in %a." Fpath.pp opam

let check_tag ~dry_run vcs tag =
  if Vcs.tag_exists ~dry_run vcs tag then Ok ()
  else
    R.error_msgf
      "CHANGES.md lists '%s' as the latest release, but no corresponding tag \
       has been found in the repository.@.Did you forget to call 'dune-release \
       tag' ?"
      tag

let assert_tag_exists ~dry_run tag =
  Vcs.get () >>= fun repo ->
  if Vcs.tag_exists ~dry_run repo tag then Ok ()
  else R.error_msgf "%s is not a valid tag" tag

let publish_distrib ~dry_run ~msg ~archive ~yes p =
  let git_for_repo r = Cmd.of_list (Cmd.to_list @@ Vcs.cmd r) in
  let curl = Cmd.(v "curl" % "-L" % "-s" % "-S" % "-K" % "-") in
  ( match Pkg.distrib_user_and_repo p with
  | Error _ as e -> if dry_run then Ok (D.user, D.repo) else e
  | r -> r )
  >>= fun (user, repo) ->
  Pkg.tag p >>= fun tag ->
  assert_tag_exists ~dry_run tag >>= fun () ->
  OS.Cmd.must_exist curl >>= fun curl ->
  Vcs.get () >>= fun vcs ->
  Ok (git_for_repo vcs) >>= fun git ->
  Pkg.tag p >>= fun tag ->
  check_tag ~dry_run vcs tag >>= fun () ->
  dev_repo p >>= fun upstr ->
  Prompt.confirm_or_abort ~yes ~question:(fun l ->
      l "Push tag %a to %a?" Text.Pp.version tag Text.Pp.url upstr)
  >>= fun () ->
  App_log.status (fun l ->
      l "Pushing tag %a to %a" Text.Pp.version tag Text.Pp.url upstr);
  Sos.run_quiet ~dry_run Cmd.(git % "push" % "--force" % upstr % tag)
  >>= fun () ->
  Config.token ~dry_run () >>= fun token ->
  Prompt.confirm_or_abort ~yes ~question:(fun l ->
      l "Create release %a on %a?" Text.Pp.version tag Text.Pp.url upstr)
  >>= fun () ->
  App_log.status (fun l ->
      l "Creating release %a on %a via github's API" Text.Pp.version tag
        Text.Pp.url upstr);
  curl_create_release ~token ~dry_run curl tag msg user repo >>= fun id ->
  App_log.success (fun l -> l "Succesfully created release with id %d" id);
  Prompt.confirm_or_abort ~yes ~question:(fun l ->
      l "Upload %a as release asset?" Text.Pp.path archive)
  >>= fun () ->
  App_log.status (fun l ->
      l "Uploading %a as a release asset for %a via github's API" Text.Pp.path
        archive Text.Pp.version tag);
  curl_upload_archive ~token ~dry_run curl archive user repo id
  >>= Parse.archive_upload_url

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
