(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup

module D = struct
  let pr_url = "${pr_url}"
  let pr_node_id = "${pr_node_id}"
  let download_url = "${download_url}"
  let release_id = 1
  let asset_name = "${asset_name}"
end

module Parse = struct
  let path_from_regexp_opt uri regexp =
    try
      Some
        ("git@github.com:"
        ^ Re.(Group.get (exec (Emacs.compile_pat regexp) uri) 1))
    with Not_found -> None

  let ssh_uri_from_http uri =
    match uri with
    | _ when Bos_setup.String.is_prefix uri ~affix:"git@" ->
        path_from_regexp_opt uri "git@github\\.com:\\(.+\\)"
    | _ when Bos_setup.String.is_prefix uri ~affix:"git://" ->
        path_from_regexp_opt uri "git://github\\.com/\\(.+\\)"
    | _ when Bos_setup.String.is_prefix uri ~affix:"https://" ->
        path_from_regexp_opt uri "https://github\\.com/\\(.+\\)"
    | _ -> None
end

(* Publish releases *)

let run_with_auth ?(default_body = `Null) ~dry_run Curl.{ url; args; meth } =
  let args = Curl_option.to_string_list args in
  if dry_run then
    Sos.show "exec:@[@ curl %a@]"
      Format.(pp_print_list ~pp_sep:pp_print_space pp_print_string)
      args
    >>| fun () -> default_body
  else
    OS.Cmd.must_exist (Cmd.v "curl") >>= fun _ ->
    let req = Curly.Request.make ~url ~meth () in
    Logs.debug (fun l ->
        l "[curl] executing request:@;<1 2>%a" Curly.Request.pp req);
    Logs.debug (fun l ->
        l "[curl] with args:@;<1 2>%a" (Fmt.list ~sep:Fmt.sp Fmt.string) args);
    match Curly.run ~args req with
    | Ok resp ->
        Logs.debug (fun l ->
            l "[curl] response received:@;<1 2>%a" Curly.Response.pp resp);
        Json.from_string resp.body
    | Error e -> R.error_msgf "curl execution failed: %a" Curly.Error.pp e

let curl_create_release ~token ~dry_run ~version ~tag ~draft msg user repo =
  let curl_t =
    Github_v3_api.Release.Request.create ~version ~tag ~msg ~user ~repo ~draft
  in
  let curl_t = Github_v3_api.with_auth ~token curl_t in
  let default_body = `Assoc [ ("id", `Int D.release_id) ] in
  run_with_auth ~dry_run ~default_body curl_t
  >>= Github_v3_api.Release.Response.release_id

let curl_upload_archive ~token ~dry_run ~yes archive user repo release_id =
  let curl_t =
    Github_v3_api.Archive.Request.upload ~archive ~user ~repo ~release_id
  in
  let curl_t = Github_v3_api.with_auth ~token curl_t in
  let default_body =
    `Assoc
      [
        ("browser_download_url", `String D.download_url);
        ("name", `String D.asset_name);
      ]
  in
  Prompt.try_again ~yes ~default_answer:Prompt.Yes
    ~question:(fun l ->
      l "Uploading %a as release asset failed. Try again?" Text.Pp.path archive)
    (fun () ->
      run_with_auth ~dry_run ~default_body curl_t >>= fun response ->
      Github_v3_api.Archive.Response.browser_download_url response
      >>= fun url ->
      Github_v3_api.Archive.Response.name response >>= fun name -> Ok (url, name))

let open_pr ~token ~dry_run ~title ~fork_owner ~branch ~opam_repo ~draft body
    pkg =
  let curl_t =
    Github_v3_api.Pull_request.Request.open_ ~title ~fork_owner ~branch ~body
      ~opam_repo ~draft
  in
  let curl_t = Github_v3_api.with_auth ~token curl_t in
  let default_body = `Assoc [ ("html_url", `String D.pr_url) ] in
  run_with_auth ~dry_run ~default_body curl_t >>= fun json ->
  (if draft then
     Pkg.build_dir pkg >>= fun build_dir ->
     Pkg.name pkg >>= fun name ->
     Pkg.version pkg >>= fun version ->
     Github_v3_api.Pull_request.Response.number json >>= fun pr_number ->
     Config.Draft_pr.set ~dry_run ~build_dir ~name ~version
       (string_of_int pr_number)
   else Ok ())
  >>= fun () -> Github_v3_api.Pull_request.Response.html_url json

let undraft_release ~token ~dry_run ~owner ~repo ~release_id ~name =
  (match int_of_string_opt release_id with
  | Some id -> Ok id
  | None -> R.error_msgf "Invalid Github Release id: %s" release_id)
  >>= fun release_id ->
  let curl_t = Github_v3_api.Release.Request.undraft ~owner ~repo ~release_id in
  let default_body =
    `Assoc [ ("browser_download_url", `String D.download_url) ]
  in
  let curl_t = Github_v3_api.with_auth ~token curl_t in
  run_with_auth ~dry_run ~default_body curl_t
  >>= Github_v3_api.Release.Response.browser_download_url ~name

let undraft_pr ~token ~dry_run ~opam_repo:(user, repo) ~pr_id =
  (match int_of_string_opt pr_id with
  | Some id -> Ok id
  | None -> R.error_msgf "Invalid Github PR number: %s" pr_id)
  >>= fun pr_id ->
  let curl_t =
    Github_v4_api.Pull_request.Request.node_id ~user ~repo ~id:pr_id
  in
  let curl_t = Github_v4_api.with_auth ~token curl_t in
  let default_body =
    `Assoc
      [
        ( "data",
          `Assoc
            [
              ( "repository",
                `Assoc
                  [ ("pullRequest", `Assoc [ ("id", `String D.pr_node_id) ]) ]
              );
            ] );
      ]
  in
  run_with_auth ~dry_run ~default_body curl_t
  >>= Github_v4_api.Pull_request.Response.node_id
  >>= fun node_id ->
  let curl_t = Github_v4_api.Pull_request.Request.ready_for_review ~node_id in
  let curl_t = Github_v4_api.with_auth ~token curl_t in
  let default_body =
    `Assoc
      [
        ( "data",
          `Assoc
            [
              ( "markPullRequestReadyForReview",
                `Assoc [ ("pullRequest", `Assoc [ ("url", `String D.pr_url) ]) ]
              );
            ] );
      ]
  in
  run_with_auth ~dry_run ~default_body curl_t
  >>= Github_v4_api.Pull_request.Response.url

let pkg_dev_repo p =
  Pkg.dev_repo p >>= function
  | Some r -> Ok r
  | None ->
      Pkg.opam p >>= fun opam ->
      R.error_msgf "The field dev-repo is missing in %a." Fpath.pp opam

let check_tag ~dry_run vcs tag =
  if Vcs.tag_exists ~dry_run vcs tag then Ok ()
  else
    R.error_msgf
      "CHANGES.md lists '%a' as the latest release, but no corresponding tag \
       has been found in the repository.@.Did you forget to call 'dune-release \
       tag' ?"
      Vcs.Tag.pp tag

let assert_tag_exists ~dry_run tag =
  Vcs.get () >>= fun repo ->
  if Vcs.tag_exists ~dry_run repo tag then Ok ()
  else R.error_msgf "%a is not a valid tag" Vcs.Tag.pp tag

(* Resolve again in case of annotated tags (most common case).
   This is a no-op for non-annotated tags. In case of error, we
   can assume that the remote is different because we checked that we
   have the tag locally. *)
let determine_remote_tag_status ~local_rev ~remote_rev vcs =
  match Vcs.commit_id ~commit_ish:remote_rev vcs with
  | Ok resolved_rev when resolved_rev = local_rev && resolved_rev = remote_rev
    ->
      (* the resolved_rev was the same as remote, thus it is unannotated *)
      `Up_to_date_unannotated
  | Ok resolved_rev when resolved_rev = local_rev ->
      (* the resolved_rev was different than the remote rev, so it must be annotated *)
      `Up_to_date_annotated
  | Ok resolved_rev -> `Points_to_different_commit resolved_rev
  | Error _ -> `Points_to_missing_object

let remote_has_up_to_date_tag vcs ~local_rev ~remote_rev tag =
  let points_to_different_commit pp_r =
    App_log.unhappy (fun l ->
        l
          "The tag %a is present on the remote but points to a different \
           commit (%a)."
          Text.Pp.tag tag pp_r ())
  in
  match determine_remote_tag_status ~local_rev ~remote_rev vcs with
  | `Up_to_date_annotated -> Ok true
  | `Up_to_date_unannotated ->
      App_log.unhappy (fun l ->
          l
            "The tag present on the remote is not annotated (it was not \
             created by dune-release tag.)");
      Ok true
  | `Points_to_different_commit different_rev ->
      points_to_different_commit (fun fmt () ->
          Text.Pp.commit fmt different_rev);
      Ok false
  | `Points_to_missing_object ->
      points_to_different_commit (fun fmt () ->
          Format.fprintf fmt "that we don't have locally");
      Ok false

let remote_has_tag_uptodate ~dry_run vcs ~dev_repo tag =
  match Vcs.tag_points_to vcs tag with
  | None -> Ok false
  | Some local_rev -> (
      Vcs.ls_remote ~dry_run vcs ~kind:`Tag ~filter:(Vcs.Tag.to_string tag)
        dev_repo
      >>= function
      | [] -> Ok false
      | (remote_rev, _) :: _ ->
          remote_has_up_to_date_tag vcs ~local_rev ~remote_rev tag)

(* Ask the user then push the tag. Guess the ssh URI from the dev-repo.
   This function can abort:
   - The user answered "N" to pushing the tag
   - The push failed

   This function does nothing if the tag is already present on the remote and
   point to the same ref. *)
let push_tag ~dry_run ~yes ~dev_repo vcs tag =
  remote_has_tag_uptodate ~dry_run vcs ~dev_repo tag >>= function
  | true ->
      App_log.status (fun l ->
          l
            "The tag %a is present and up-to-date on the remote: skipping the \
             tag push"
            Text.Pp.tag tag);
      Ok () (* No need to push, avoiding the need to guess the uri. *)
  | false -> (
      let uri =
        match Parse.ssh_uri_from_http dev_repo with
        | Some uri -> uri
        | None ->
            App_log.unhappy (fun l ->
                l
                  "The uri %a is not recognized as a gihub uri, we are going \
                   to assume it is already a ssh uri."
                  Text.Pp.url dev_repo);
            dev_repo
      in
      Prompt.confirm_or_abort ~yes
        ~question:(fun l ->
          l "Push tag %a to %a?" Text.Pp.tag tag Text.Pp.url uri)
        ~default_answer:Yes
      >>= fun () ->
      App_log.status (fun l ->
          l "Pushing tag %a to %a" Text.Pp.tag tag Text.Pp.url uri);
      match
        Vcs.run_git_quiet vcs ~dry_run
          Cmd.(v "push" % "--force" % uri % Vcs.Tag.to_string tag)
      with
      | Ok () as ok -> ok
      | Error (`Msg e) ->
          R.error_msgf
            "%s\n\
             Pushing the tag failed, please push it manually and run the \
             command again"
            e)

let curl_get_release ~dry_run ~token ~tag ~user ~repo =
  let curl_t = Github_v3_api.Release.Request.get ~tag ~user ~repo in
  let curl_t = Github_v3_api.with_auth ~token curl_t in
  run_with_auth ~dry_run curl_t >>= Github_v3_api.Release.Response.release_id

let create_release ~dry_run ~yes ~dev_repo ~token ~msg ~tag ~version ~user ~repo
    ~draft =
  match curl_get_release ~dry_run ~token ~tag ~user ~repo with
  | Error _ ->
      Prompt.(
        confirm_or_abort ~yes
          ~question:(fun l ->
            l "Create %a %a on %a?" Text.Pp.maybe_draft (draft, "release")
              Text.Pp.version version Text.Pp.url dev_repo)
          ~default_answer:Yes)
      >>= fun () ->
      App_log.status (fun l ->
          l "Creating %a %a on %a via github's API" Text.Pp.maybe_draft
            (draft, "release") Text.Pp.version version Text.Pp.url dev_repo);
      curl_create_release ~token ~dry_run ~version ~tag msg user repo ~draft
      >>= fun id ->
      App_log.success (fun l ->
          l "Successfully created %a with id %d" Text.Pp.maybe_draft
            (draft, "release") id);
      Ok id
  | Ok id ->
      App_log.status (fun l -> l "Release with id %d already exists" id);
      Ok id

let publish_distrib ~token ?dev_repo ~dry_run ~msg ~archive ~yes ~draft p =
  Pkg.infer_github_repo p >>= fun { owner; repo } ->
  Pkg.tag p >>= fun tag ->
  assert_tag_exists ~dry_run tag >>= fun () ->
  Vcs.get () >>= fun vcs ->
  check_tag ~dry_run vcs tag >>= fun () ->
  let dev_repo =
    match dev_repo with Some d -> Ok d | None -> pkg_dev_repo p
  in
  dev_repo >>= fun dev_repo ->
  Pkg.build_dir p >>= fun build_dir ->
  Pkg.name p >>= fun name ->
  Pkg.version p >>= fun version ->
  push_tag ~dry_run ~yes ~dev_repo vcs tag >>= fun () ->
  create_release ~dry_run ~yes ~dev_repo ~token ~version ~msg ~tag ~user:owner
    ~repo ~draft
  >>= fun id ->
  (if draft then
     Config.Draft_release.set ~dry_run ~build_dir ~name ~version
       (string_of_int id)
   else Config.Draft_release.unset ~dry_run ~build_dir ~name ~version)
  >>= fun () ->
  Prompt.(
    confirm_or_abort ~yes
      ~question:(fun l -> l "Upload %a as release asset?" Text.Pp.path archive)
      ~default_answer:Yes)
  >>= fun () ->
  App_log.status (fun l ->
      l "Uploading %a as a release asset for %a via github's API" Text.Pp.path
        archive Text.Pp.version version);
  curl_upload_archive ~token ~dry_run ~yes archive owner repo id
  >>= fun (url, asset_name) ->
  (if draft then
     Config.Release_asset_name.set ~dry_run ~build_dir ~name ~version asset_name
   else Config.Release_asset_name.unset ~dry_run ~build_dir ~name ~version)
  >>= fun () -> Ok url

let rec pp_list pp ppf = function
  | [] -> ()
  | [ x ] -> pp ppf x
  | [ x; y ] -> Fmt.pf ppf "%a and %a" pp x pp y
  | h :: t -> Fmt.pf ppf "%a, %a" pp h (pp_list pp) t

let pr_title ~names ~version ~project_name ~pkgs_to_submit =
  let number_of_pkgs = List.length names in
  let pp_name ppf =
    match (pkgs_to_submit, project_name) with
    | [], Some project_name when number_of_pkgs > 1 ->
        Format.fprintf ppf "%s (%d packages)" project_name number_of_pkgs
    | [], _ -> pp_list Fmt.string ppf names
    | pkgs_to_submit, _ -> pp_list Fmt.string ppf pkgs_to_submit
  in
  strf "[new release] %t (%a)" pp_name Version.pp version

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
