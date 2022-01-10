(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup
open Dune_release

let vcs_tag repo pkg tag version ~dry_run ~commit_ish ~force ~sign ~delete ~msg
    ~yes =
  App_log.status (fun l -> l "Using tag \"%a\"" Vcs.Tag.pp tag);
  Vcs.commit_id ~dirty:false ~commit_ish repo
  |> R.reword_error (fun (`Msg msg) ->
         R.msgf "Due to invalid commit-ish `%s`:\n%s" commit_ish msg)
  >>= fun commit ->
  let tag_commit_opt = Vcs.tag_points_to repo tag in
  match (tag_commit_opt, delete) with
  | Some tag_commit, true ->
      let question =
        if tag_commit = commit then
          Prompt.(
            confirm_or_abort ~yes
              ~question:(fun l -> l "Delete tag %a?" Text.Pp.tag tag)
              ~default_answer:Yes)
        else
          Prompt.(
            confirm_or_abort ~yes
              ~question:(fun l ->
                l
                  "%a Tag %a does not point to the commit you've provided \
                   (default: HEAD). Do you want to delete it anyways?"
                  Fmt.(styled `Red string)
                  "Warning:" Text.Pp.tag tag)
              ~default_answer:No)
      in
      question >>= fun () ->
      Vcs.delete_tag ~dry_run repo tag >>| fun () ->
      App_log.success (fun m -> m "Deleted tag %a" Text.Pp.tag tag)
  | None, true ->
      Ok
        (App_log.status (fun apply_log_l ->
             apply_log_l "Nothing to be deleted: there is no tag %a."
               Text.Pp.tag tag))
  | Some tag_commit, false ->
      if tag_commit = commit then
        Ok
          (App_log.status (fun apply_log_l ->
               apply_log_l "Nothing to be done: tag already exists."))
      else
        R.error_msgf
          "A tag with name %a already exists, but points to a different \
           commit. You can delete that tag using the `-d` flag."
          Text.Pp.tag tag
  | None, false ->
      Prompt.(
        confirm_or_abort ~yes
          ~question:(fun l ->
            l "Create git tag %a for %a?" Text.Pp.tag tag Text.Pp.commit
              commit_ish)
          ~default_answer:Yes)
      >>= fun () ->
      (match msg with
      | Some msg -> Ok msg
      | None ->
          Pkg.publish_msg pkg >>| fun msg ->
          strf "Release %a\n\n%s" Version.pp version msg)
      >>= fun msg ->
      Vcs.tag repo ~dry_run ~force ~sign ~msg ~commit_ish tag >>| fun () ->
      App_log.success (fun m ->
          m "Tagged %a with version %a" Text.Pp.commit commit_ish Text.Pp.tag
            tag)

let tag () (`Dry_run dry_run) (`Change_log change_log) (`Keep_v keep_v)
    (`Version version) (`Commit_ish commit_ish) (`Force force) (`Sign sign)
    (`Delete delete) (`Msg msg) (`Yes yes) =
  Config.keep_v ~keep_v
  >>= (fun keep_v ->
        let pkg = Pkg.v ~dry_run ~keep_v ?change_log () in
        Vcs.get () >>= fun vcs ->
        (match version with
        | Some v -> Ok (v, Version.to_tag vcs v)
        | None ->
            Pkg.change_log pkg >>= fun changelog ->
            App_log.status (fun l ->
                l "Extracting tag from first entry in %a" Text.Pp.path changelog);
            Pkg.extract_version pkg >>= fun cl ->
            Ok (Pkg.version_of_changelog pkg cl, Version.Changelog.to_tag vcs cl))
        >>= fun (version, tag) ->
        vcs_tag vcs pkg tag version ~dry_run ~commit_ish ~force ~sign ~delete
          ~msg ~yes
        >>= fun () -> Ok 0)
  |> Cli.handle_error

(* Command line interface *)

open Cmdliner

let version =
  let doc =
    "The version tag to use. If absent, automatically extracted from the \
     package's change log."
  in
  Cli.named
    (fun x -> `Version x)
    Arg.(value & pos 0 (some Cli.version) None & info [] ~doc ~docv:"VERSION")

let commit =
  let doc = "Commit-ish $(docv) to tag." in
  Cli.named
    (fun x -> `Commit_ish x)
    Arg.(value & opt string "HEAD" & info [ "commit" ] ~doc ~docv:"COMMIT-ISH")

let msg =
  let doc =
    "Commit message for the tag. If absent, the message 'Distribution \
     $(i,VERSION)' is used."
  in
  Cli.named
    (fun x -> `Msg x)
    Arg.(
      value & opt (some string) None & info [ "m"; "message" ] ~doc ~docv:"MSG")

let sign =
  let doc = "Sign the tag using the VCS's default signing key." in
  Cli.named (fun x -> `Sign x) Arg.(value & flag & info [ "s"; "sign" ] ~doc)

let force =
  let doc = "If the tag exists, replace it rather than fail." in
  Cli.named (fun x -> `Force x) Arg.(value & flag & info [ "f"; "force" ] ~doc)

let delete =
  let doc = "Delete the specified tag rather than create it." in
  Cli.named
    (fun x -> `Delete x)
    Arg.(value & flag & info [ "d"; "delete" ] ~doc)

let doc = "Tag the package's source repository with a version"
let sdocs = Manpage.s_common_options
let exits = Cli.exits
let man_xrefs = [ `Main; `Cmd "log" ]

let man =
  [
    `S Manpage.s_description;
    `P
      "The $(tname) command tags the package's VCS HEAD commit with a version. \
       If the version is not specified on the command line it is automatically \
       extracted from the package's change log.";
  ]

let cmd =
  ( Term.(
      pure tag $ Cli.setup $ Cli.dry_run $ Cli.change_log $ Cli.keep_v $ version
      $ commit $ force $ sign $ delete $ msg $ Cli.yes),
    Term.info "tag" ~doc ~sdocs ~exits ~man ~man_xrefs )

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
