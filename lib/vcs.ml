(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup

(* Version control system repositories *)

module Tag = struct
  type t = string

  let pp = Fmt.string
  let equal = String.equal
  let to_string x = x

  (* no escaping here in case the user wants to force a literal tag *)
  let of_string x = x
end

type commit_ish = string

module Tag_or_commit_ish = struct
  type t = Tag of Tag.t | Commit_ish of commit_ish

  let to_commit_ish = function Tag c | Commit_ish c -> c
end

type kind = [ `Git | `Hg ]

let dirtify id = id ^ "-dirty"

type t = kind * Cmd.t * Fpath.t

let git =
  let git = Cmd.v (OS.Env.opt_var "DUNE_RELEASE_GIT" ~absent:"git") in
  lazy (OS.Cmd.exists git >>= fun exists -> Ok (exists, git))

let hg =
  let hg = Cmd.v (OS.Env.opt_var "DUNE_RELEASE_HG" ~absent:"hg") in
  lazy (OS.Cmd.exists hg >>= fun exists -> Ok (exists, hg))

let vcs_cmd kind cmd dir =
  match kind with
  | `Git -> Cmd.(cmd % "--git-dir" % dir)
  | `Hg -> Cmd.(cmd % "--repository" % dir)

let v k cmd ~dir = (k, cmd, dir)
let dir (_, _, dir) = dir
let cmd (kind, cmd, dir) = vcs_cmd kind cmd Fpath.(to_string dir)

(* Git support *)

let git_work_tree (_, _, dir) = Cmd.(v "--work-tree" % p Fpath.(parent dir))

let find_git () =
  Lazy.force git >>= function
  | false, _ -> Ok None
  | true, git -> (
      let git_dir = Cmd.(git % "rev-parse" % "--git-dir") in
      OS.Cmd.(run_out ~err:err_null git_dir |> out_string) >>= function
      | dir, (_, `Exited 0) -> Ok (Some (v `Git git ~dir:Fpath.(v dir)))
      | _ -> Ok None)

module Default = struct
  let string = Sos.out ""
  let unit = Sos.out ()
  let list = Sos.out []
end

let run_git ~dry_run ?force ~default r args out =
  let git = Cmd.(cmd r %% args) in
  Sos.run_out_err ~dry_run ~sandbox:false ?force git ~default out
  >>= fun response ->
  match response.status with
  | `Exited 0 -> Ok response.output
  | `Exited 128
    when String.is_prefix response.err_msg
           ~affix:"git@github.com: Permission denied" ->
      let hint =
        "\n\
         Hint from dune-release: the reason for the Permission denied error is \
         probably a failing ssh connection. For more information, see \
         https://github.com/tarides/dune-release#publish-troubleshooting ."
      in
      Sos.cmd_error git (Some (response.err_msg ^ hint)) response.status
  | _ -> Sos.cmd_error git (Some response.err_msg) response.status

let run_git_quiet ~dry_run ?force r args =
  run_git ~dry_run ?force ~default:Default.unit r args OS.Cmd.out_null

let run_git_string ~dry_run ?force ~default r args =
  run_git ~dry_run ?force ~default r args OS.Cmd.out_string

let git_is_dirty r =
  let status_cmd = Cmd.(cmd r %% git_work_tree r % "status" % "--porcelain") in
  Sos.run_out_err ~dry_run:false status_cmd ~default:Default.string
    OS.Cmd.out_string
  >>= function
  | { output = ""; status = `Exited 0; _ } -> Ok false
  | { status = `Exited 0; _ } -> Ok true
  | { err_msg; status; _ } -> Sos.cmd_error status_cmd (Some err_msg) status

let dirtify_if ~dirty r id =
  match dirty with
  | false -> Ok id
  | true ->
      git_is_dirty r >>= fun is_dirty ->
      Ok (if is_dirty then dirtify id else id)

let git_commit_id ~dirty r commit_ish =
  let dirty = dirty && commit_ish = "HEAD" in
  let id = Cmd.(v "rev-parse" % "--verify" % (commit_ish ^ "^0")) in
  run_git_string ~dry_run:false r id ~default:Default.string >>= fun id ->
  dirtify_if ~dirty r id

let git_commit_ptime_s ~dry_run r commit_ish =
  let commit_ish = commit_ish ^ "^0" in
  let time = Cmd.(v "show" % "-s" % "--format=%ct" % commit_ish) in
  run_git_string ~dry_run ~force:true r time ~default:Default.string
  >>= fun ptime ->
  try Ok (Int64.of_string ptime)
  with Failure e ->
    R.error_msgf "Could not parse timestamp from %S: %s" ptime e

let git_describe ~dirty r commit_ish =
  let dirty = dirty && commit_ish = "HEAD" in
  let git_describe =
    Cmd.(
      git_work_tree r % "describe" % "--always" % "--tags"
      %% on dirty (v "--dirty")
      %% on (not dirty) (v commit_ish))
  in
  run_git_string ~dry_run:false r git_describe ~default:Default.string

let git_tag_rev tag = "refs/tags/" ^ tag

let git_tag_exists ~dry_run r tag =
  match
    run_git_quiet ~dry_run r Cmd.(v "rev-parse" % "--verify" % git_tag_rev tag)
  with
  | Ok () -> true
  | _ -> false

let git_branch_exists ~dry_run r br =
  let cmd =
    Cmd.(v "show-ref" % "--verify" % "--quiet" % ("refs/heads/" ^ br))
  in
  match run_git_quiet ~dry_run r cmd with Ok () -> true | _ -> false

let git_clone ~dry_run ?force ?branch ~dir:d r =
  let branch =
    match branch with None -> Cmd.empty | Some b -> Cmd.(v "-b" % b)
  in
  let clone = Cmd.(v "clone" % "--local" %% branch % p (dir r) % p d) in
  run_git ~dry_run ?force r clone ~default:Default.unit OS.Cmd.out_stdout
  >>= fun () -> Ok ()

let git_checkout ~dry_run r ~branch ~commit_ish =
  let branch =
    match branch with None -> Cmd.empty | Some branch -> Cmd.(v "-b" % branch)
  in
  run_git_string ~dry_run ~force:true r
    Cmd.(git_work_tree r % "checkout" % "--quiet" %% branch % commit_ish)
    ~default:Default.string
  >>= fun _ -> Ok ()

let git_change_branch ~dry_run r ~branch =
  run_git_string ~dry_run ~force:true r
    Cmd.(git_work_tree r % "checkout" % branch)
    ~default:Default.string
  >>= fun _ -> Ok ()

let git_tag ~dry_run r ~force ~sign ~msg ~commit_ish tag =
  let msg = match msg with None -> Cmd.empty | Some m -> Cmd.(v "-m" % m) in
  let flags = Cmd.(on force (v "-f") %% on sign (v "-s")) in
  run_git ~dry_run r
    Cmd.(v "tag" % "-a" %% flags %% msg % tag % commit_ish)
    ~default:Default.unit OS.Cmd.out_stdout

let git_delete_tag ~dry_run r tag =
  run_git_quiet ~dry_run r Cmd.(v "tag" % "-d" % tag)

let git_ls_remote ~dry_run r ~kind ~filter upstream =
  let rec parse_ls_remote acc = function
    | [] -> Ok (List.rev acc)
    | line :: tl -> (
        match String.fields ~empty:false line with
        | [ rev; ref ] -> parse_ls_remote ((rev, ref) :: acc) tl
        | _ -> R.error_msgf "Could not parse output of git ls-remote")
  in
  let kind_arg =
    match kind with
    | `All -> Cmd.empty
    | `Branch -> Cmd.v "--heads"
    | `Tag -> Cmd.v "--tags"
  and filter_arg =
    match filter with Some filter -> Cmd.v filter | None -> Cmd.empty
  in
  run_git ~dry_run r
    Cmd.(v "ls-remote" % "--quiet" %% kind_arg % upstream %% filter_arg)
    ~default:Default.list OS.Cmd.out_lines
  >>= parse_ls_remote []

let git_submodule_update ~dry_run r =
  run_git_quiet ~dry_run r Cmd.(v "submodule" % "update" % "--init")

(* See the reference here: https://git-scm.com/docs/git-check-ref-format
 * Similar escape as DEP-14: https://dep-team.pages.debian.net/deps/dep14/ *)
let git_escape_tag t = String.map (function '~' -> '_' | c -> c) t
let git_unescape_tag t = String.map (function '_' -> '~' | c -> c) t

(* Hg support *)

(* Mercurial allows everything but :, \r and \n, but all these characters are
 * unlikely to show up in versions so we just pass things through.
 *)
let hg_escape_tag t = t
let hg_unescape_tag t = t
let hg_rev commit_ish = match commit_ish with "HEAD" -> "tip" | c -> c

let find_hg () =
  Lazy.force hg >>= function
  | false, _ -> Ok None
  | true, hg -> (
      let hg_root = Cmd.(hg % "root") in
      OS.Cmd.(run_out ~err:err_null hg_root |> out_string) >>= function
      | dir, (_, `Exited 0) -> Ok (Some (v `Hg hg ~dir:Fpath.(v dir)))
      | _ -> Ok None)

let run_hg r args out =
  let hg = Cmd.(cmd r %% args) in
  OS.Cmd.(run_out hg |> out) >>= function
  | v, (_, `Exited 0) -> Ok v
  | _, (_, st) -> Sos.cmd_error hg None st

let hg_id r ~rev =
  run_hg r Cmd.(v "id" % "-i" % "--rev" % rev) OS.Cmd.out_string >>= fun id ->
  let len = String.length id in
  let is_dirty = String.length id > 0 && id.[len - 1] = '+' in
  let id = if is_dirty then String.with_range id ~len:(len - 1) else id in
  Ok (id, is_dirty)

let hg_is_dirty r = hg_id r ~rev:"tip" >>= function _, is_dirty -> Ok is_dirty

let hg_commit_id ~dirty r ~rev =
  hg_id r ~rev >>= fun (id, is_dirty) ->
  Ok (if is_dirty && dirty then dirtify id else id)

let hg_commit_ptime_s r ~rev =
  let time =
    Cmd.(v "log" % "--template" % "'{date(date, \"%s\")}'" % "--rev" % rev)
  in
  run_hg r time OS.Cmd.out_string >>= fun ptime ->
  try Ok (Int64.of_string ptime)
  with Failure _ -> R.error_msgf "Could not parse timestamp from %S" ptime

let hg_describe ~dirty r ~rev =
  let get_distance s =
    try Ok (Int64.of_string s)
    with Failure _ ->
      R.error_msgf "%a: Could not parse hg tag distance." Fpath.pp (dir r)
  in
  let parent t =
    run_hg r
      Cmd.(v "parent" % "--rev" % rev % "--template" % t)
      OS.Cmd.out_string
  in
  ( parent "{latesttagdistance}" >>= get_distance >>= function
    | 1L -> parent "{latesttag}"
    | _ -> parent "{latesttag}-{latesttagdistance}-{node|short}" )
  >>= fun descr ->
  match dirty with
  | false -> Ok descr
  | true ->
      hg_id ~rev:"tip" r >>= fun (_, is_dirty) ->
      Ok (if is_dirty then dirtify descr else descr)

(* hg order is reverse from git *)

let hg_clone r ~dir:d =
  let clone = Cmd.(v "clone" % p (dir r) % p d) in
  run_hg r clone OS.Cmd.out_stdout

let hg_checkout r ~branch ~rev =
  run_hg r Cmd.(v "update" % "--rev" % rev) OS.Cmd.out_string >>= fun _ ->
  match branch with
  | None -> Ok ()
  | Some branch ->
      run_hg r Cmd.(v "branch" % branch) OS.Cmd.out_string >>= fun _ -> Ok ()

let hg_change_branch r ~branch =
  run_hg r Cmd.(v "update" % branch) OS.Cmd.out_string >>= fun _ -> Ok ()

let hg_tag r ~force ~sign ~msg ~rev tag =
  if sign then R.error_msgf "Tag signing is not supported by hg"
  else
    let msg = match msg with None -> Cmd.empty | Some m -> Cmd.(v "-m" % m) in
    run_hg r
      Cmd.(v "tag" %% on force (v "-f") %% msg % "--rev" % rev % tag)
      OS.Cmd.out_stdout

let hg_delete_tag r tag =
  run_hg r Cmd.(v "tag" % "--remove" % tag) OS.Cmd.out_stdout

(* Generic VCS support *)

let find ?dir () =
  match dir with
  | None -> (
      find_git () >>= function Some _ as v -> Ok v | None -> find_hg ())
  | Some dir -> (
      let git_dir = Fpath.(dir / ".git") in
      OS.Dir.exists git_dir >>= function
      | true -> (
          Lazy.force git >>= function
          | _, cmd -> Ok (Some (v `Git cmd ~dir:git_dir)))
      | false -> (
          let hg_dir = Fpath.(dir / ".hg") in
          OS.Dir.exists hg_dir >>= function
          | false -> Ok None
          | true -> (
              Lazy.force hg >>= function
              | _, cmd -> Ok (Some (v `Hg cmd ~dir:hg_dir)))))

let get ?dir () =
  find ?dir () >>= function
  | Some r -> Ok r
  | None -> (
      let dir =
        match dir with None -> OS.Dir.current () | Some dir -> Ok dir
      in
      dir >>= function
      | dir -> R.error_msgf "%a: No VCS repository found" Fpath.pp dir)

(* Repository state *)

let is_dirty = function
  | (`Git, _, _) as r -> git_is_dirty r
  | (`Hg, _, _) as r -> hg_is_dirty r

let commit_id ?(dirty = true) ?(commit_ish = "HEAD") = function
  | (`Git, _, _) as r -> git_commit_id ~dirty r commit_ish
  | (`Hg, _, _) as r -> hg_commit_id ~dirty r ~rev:(hg_rev commit_ish)

let commit_ptime_s ~dry_run ?(commit_ish = Tag_or_commit_ish.Commit_ish "HEAD")
    t =
  let commit_ish = Tag_or_commit_ish.to_commit_ish commit_ish in
  match t with
  | (`Git, _, _) as r -> git_commit_ptime_s ~dry_run r commit_ish
  | (`Hg, _, _) as r -> hg_commit_ptime_s r ~rev:(hg_rev commit_ish)

let describe ?(dirty = true) ?(commit_ish = "HEAD") = function
  | (`Git, _, _) as r -> git_describe ~dirty r commit_ish
  | (`Hg, _, _) as r -> hg_describe ~dirty r ~rev:(hg_rev commit_ish)

let get_tag vcs = describe ~dirty:false vcs

let tag_exists ~dry_run r tag =
  match r with
  | (`Git, _, _) as r -> git_tag_exists r ~dry_run tag
  | `Hg, _, _ -> failwith "TODO"

let tag_points_to r tag =
  let tag' = match r with `Git, _, _ -> git_tag_rev tag | `Hg, _, _ -> tag in
  commit_id ~dirty:false ~commit_ish:tag' r |> R.to_option

let branch_exists ~dry_run r tag =
  match r with
  | (`Git, _, _) as r -> git_branch_exists r ~dry_run tag
  | `Hg, _, _ -> failwith "TODO"

(* Operations *)

let clone ~dry_run ?force ?branch ~dir r =
  match r with
  | (`Git, _, _) as r -> git_clone ~dry_run ?force ?branch ~dir r
  | (`Hg, _, _) as r -> hg_clone r ~dir

let checkout ~dry_run ?branch r ~commit_ish =
  let commit_ish = Tag_or_commit_ish.to_commit_ish commit_ish in
  match r with
  | (`Git, _, _) as r -> git_checkout ~dry_run r ~branch ~commit_ish
  | (`Hg, _, _) as r -> hg_checkout r ~branch ~rev:(hg_rev commit_ish)

let change_branch ~dry_run ~branch r =
  match r with
  | (`Git, _, _) as r -> git_change_branch ~dry_run r ~branch
  | (`Hg, _, _) as r -> hg_change_branch r ~branch

let tag ~dry_run ?(force = false) ?(sign = false) ?msg ?(commit_ish = "HEAD") r
    tag =
  match r with
  | (`Git, _, _) as r -> git_tag ~dry_run r ~force ~sign ~msg ~commit_ish tag
  | (`Hg, _, _) as r -> hg_tag r ~force ~sign ~msg ~rev:(hg_rev commit_ish) tag

let delete_tag ~dry_run r tag =
  match r with
  | (`Git, _, _) as r -> git_delete_tag ~dry_run r tag
  | (`Hg, _, _) as r -> hg_delete_tag r tag

let ls_remote ~dry_run r ?(kind = `All) ?filter upstream =
  match r with
  | (`Git, _, _) as r -> git_ls_remote ~dry_run r ~kind ~filter upstream
  | `Hg, _, _ -> R.error_msgf "ls_remote is only implemented for Git"

let submodule_update ~dry_run r =
  match r with
  | (`Git, _, _) as r -> git_submodule_update ~dry_run r
  | `Hg, _, _ -> R.error_msgf "submodule update is not supported with mercurial"

let escape_tag = function
  | `Git, _, _ -> git_escape_tag
  | `Hg, _, _ -> hg_escape_tag

let unescape_tag = function
  | `Git, _, _ -> git_unescape_tag
  | `Hg, _, _ -> hg_unescape_tag

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
