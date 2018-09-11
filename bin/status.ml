(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup
open Dune_release

let pp_since ppf = function
| "" -> ()
| v -> Fmt.pf ppf " since %a" Text.Pp.version v

let pp_dirty ppf = function
| false -> ()
| true -> Fmt.pf ppf "The repository is %a.@," Text.Pp.dirty ()

let pp_commit ppf (id, log) =
  Fmt.(pf ppf "%a %s" Text.Pp.commit id log)

let pp_status ppf (dirty, version, changes) = match changes with
| [] when not dirty -> Fmt.pf ppf "@[<v>No changes%a@]" pp_since version
| changes ->
    Fmt.pf ppf "@[<v>Changes%a:@,%a%a@]"
      pp_since version pp_dirty dirty (Fmt.list pp_commit) changes

let parse_version v =
  let prefix, version =
    if String.is_prefix ~affix:"v" v
    then Some "v", String.with_index_range ~first:1 v
    else None, v
  in
  try match String.cut ~sep:"." version with
  | None -> None
  | Some (maj, rest) ->
      let maj = int_of_string maj in
      match String.cut ~sep:"." rest with
      | None ->
          begin match String.cut ~sep:"+" rest with
          | None -> Some (prefix, maj, int_of_string rest, 0, None)
          | Some (min, i) ->  Some (prefix, maj, int_of_string min, 0, Some i)
          end
      | Some (min, rest) ->
          let min = int_of_string min in
          begin match String.cut ~sep:"+" rest with
          | None -> Some (prefix, maj, min, int_of_string rest, None)
          | Some (p, i) -> Some (prefix, maj, min, int_of_string p, Some i)
          end
  with
  | Failure _ -> None

let find_latest_version_tag repo =
  let rev_compare v v' = -1 * compare v v' in
  let parse_tag acc t = match parse_version t with
  | None -> acc
  | Some v -> (v, t) :: acc
  in
  Vcs.tags repo >>| fun tags ->
  match List.(sort rev_compare (fold_left parse_tag [] tags)) with
  | (_, latest) :: _ -> Some latest
  | [] -> None

let find_after repo = function
| Some after -> Ok after
| None ->
    find_latest_version_tag repo >>| function
    | None ->
        Logs.info (fun m -> m "No VCS version tag found."); ""
    | Some tag ->
        Logs.info (fun m -> m "Latest VCS version tag found: %s" tag); tag

let status () _ after until =
  begin
    Vcs.get ()
    >>= fun repo -> Vcs.is_dirty repo
    >>= fun dirty -> find_after repo after
    >>= fun after -> Vcs.changes repo ~after ~until
    >>= fun changes ->
    Logs.app (fun m -> m "%a" pp_status (dirty, after, changes));
    Ok (if dirty || changes <> [] then 0 else 1)
  end
  |> Cli.handle_error

(* Command line interface *)

open Cmdliner

let after =
  let doc = "Commit-ish $(docv) after which commits are considered.
             Default is the latest VCS version tag of the form [v]X.Y.Z[+info]."
  in
  Arg.(value & opt (some string) None & info ["after"] ~doc ~docv:"COMMIT-ISH")

let until =
  let doc = "Commit-ish $(docv) until which commits are considered." in
  let docv = "COMMIT-ISH" in
  Arg.(value & opt string "HEAD" & info ["until"] ~doc ~docv)

let doc = "List commits to publish in the next distribution"
let sdocs = Manpage.s_common_options
let exits =
  (Term.exit_info 0 ~doc:"changes have been detected.") ::
  (Term.exit_info 1 ~doc:"no changes have been detected.") ::
  Term.default_error_exits

let man_xrefs = [ `Main ]
let man =
  [ `S Manpage.s_description;
    `P "The $(tname) command consults the package's VCS and outputs the
        list of commits that define the changes for the next distribution." ]

let cmd =
  Term.(pure status $ Cli.setup $ Cli.dist_name $ after $ until),
  Term.info "status" ~doc ~sdocs ~exits ~man ~man_xrefs

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
