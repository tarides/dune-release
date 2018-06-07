(*
 * Copyright (c) 2018 Thomas Gazagnaire <thomas@gazagnaire.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

open Bos_setup

type error = R.msg

let root = match OS.Dir.current () with
| Error (`Msg e) -> Fmt.failwith "invalid root: %s" e
| Ok d -> d

let current_dir () =
  match OS.Dir.current () with
  | Error (`Msg e) -> Fmt.failwith "invalid current directory: %s" e
  | Ok dir         ->
      if Fpath.equal dir root then None else
      match Fpath.relativize ~root dir with
      | None   -> assert false
      | Some d ->
          assert (List.hd (Fpath.segs d) = "_build");
          Some d

let last_dir = ref root

let show ?(action=`Skip) fmt =
  let pp_action ppf = function
  | `Skip -> Fmt.(styled `Yellow string) ppf "-:"
  | `Done -> Fmt.(styled `Green string) ppf "=>"
  in
  let pp_cwd ppf () = match current_dir () with
  | None   -> ()
  | Some d ->
      if not (Fpath.equal d !last_dir) then (
        last_dir := d;
        Fmt.pf ppf "   [in %a]\n" Fmt.(styled `Underline Fpath.pp) d
      )
  in
  Fmt.kstrf (fun s ->
      Logs.app (fun m ->m "%a%a %s" pp_cwd () pp_action action s);
      Ok ()
    ) fmt

let run ~dry_run ?(force=false) v =
  if not dry_run then OS.Cmd.run v
  else if not force then show "exec:@[@ %a@]" Cmd.pp v
  else (
    let _ = show ~action:`Done "exec:@[@ %a@]" Cmd.pp v in
    OS.Cmd.run v
  )

let run_out ~dry_run ?(force=false) ?err ~default v f =
  if not dry_run then OS.Cmd.run_out ?err v |> f
  else if not force then
    let _ = show "exec:@[@ %a@]" Cmd.pp v in
    Ok default
  else (
    let _ = show ~action:`Done "exec:@[@ %a@]" Cmd.pp v in
    OS.Cmd.run_out ?err v |> f
  )

let run_io ~dry_run ?(force=false) ~default v i f =
  if not dry_run then OS.Cmd.run_io v i |> f
  else if not force then
    let _ = show "exec:@[@ %a@]" Cmd.pp v in
    Ok default
  else (
    let _ = show ~action:`Done "exec:@[@ %a@]" Cmd.pp v in
    OS.Cmd.run_io v i |> f
  )

let delete_dir ~dry_run ?(force=false) dir =
  if not dry_run then OS.Dir.delete ~recurse:true dir
  else (
    let dir' = match current_dir () with
    | None   -> dir
    | Some d -> Fpath.(normalize @@ d // dir)
    in
    if not force then show "rmdir %a" Fpath.pp dir'
    else (
      let _ = show ~action:`Done "rmdir %a" Fpath.pp dir' in
      OS.Dir.delete ~recurse:true dir
    )
  )

let delete_path ~dry_run p =
  if not dry_run then OS.Path.delete ~recurse:true p
  else (
    let p' = match current_dir () with
    | None   -> p
    | Some d -> Fpath.(normalize @@ d // p)
    in
    let _ = show ~action:`Done "rm %a" Fpath.pp p' in
    Ok ()
  )

let write_file ~dry_run ?(force=false) p v =
  if not dry_run then OS.File.write p v
  else if not force then show "write %a" Fpath.pp p
  else (
    let _ = show ~action:`Done "write %a" Fpath.pp p in
    OS.File.write p v
  )

let read_file ~dry_run p =
  if not dry_run then OS.File.read p
  else match OS.File.exists p with
  | Ok true ->
      let _ = show ~action:`Done "read %a" Fpath.pp p in
      OS.File.read p
  | _ ->
      let _ = show "read %a" Fpath.pp p in
      Ok ""

let file_exists ~dry_run p =
  if not dry_run then OS.File.exists p
  else
  let _ = show "exists %a" Fpath.pp p in
  Ok true

let with_dir ~dry_run dir f x =
  if not dry_run then OS.Dir.with_current dir f x
  else match OS.Dir.exists dir with
  | Ok true ->
      let _ = show ~action:`Done "chdir %a" Fpath.pp dir in
      OS.Dir.with_current dir f x
  | _ ->
      let _ = show "chdir %a" Fpath.pp dir in
      Ok (f x)

let file_must_exist ~dry_run f =
  if not dry_run then OS.File.must_exist f
  else
  let _ = match OS.File.exists f with
  | Ok true -> show ~action:`Done "must exists %a" Fpath.pp f
  | _       -> show "must exists %a" Fpath.pp f
  in
  Ok f

let out y =
  match OS.Cmd.run_out Cmd.(v "true") |> OS.Cmd.out_string with
  | Ok (_, x) -> y, x
  | Error _   -> assert false
