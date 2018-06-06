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

type error = Rresult.R.msg

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

let show ?(color=`Yellow) fmt =
  Fmt.kstrf (fun s ->
      let pp_cwd ppf () = match current_dir () with
      | None   -> ()
      | Some d -> Fmt.pf ppf "[%a] " Fmt.(styled `Underline Fpath.pp) d
      in
      Logs.app (fun m ->m "%a %a%s" Fmt.(styled color string) "=>" pp_cwd () s);
      Ok ()
    ) fmt

let run ~dry_run v =
  if not dry_run then OS.Cmd.run v
  else show "exec:@[@ %a@]" Cmd.pp v

let run_out ~dry_run ?err v =
  if not dry_run then OS.Cmd.run_out v
  else
  let _ = show "exec:@[@ %a@]" Cmd.pp v in
  OS.Cmd.run_out ?err Cmd.(v "true")

let run_io ~dry_run ~default v i f =
  if not dry_run then OS.Cmd.run_io v i |> f
  else
  let _ = show "exec:@[@ %a@]" Cmd.pp v in
  Ok default

let delete_dir ~dry_run dir =
  if not dry_run then OS.Dir.delete ~recurse:true dir
  else (
    let dir' = match current_dir () with
    | None   -> dir
    | Some d -> Fpath.(d // dir)
    in
    let _ = show ~color:`Green "rmdir %a" Fpath.pp dir' in
    OS.Dir.delete ~recurse:true dir
  )

let delete_path ~dry_run p =
  if not dry_run then OS.Path.delete ~recurse:true p
  else (
    let p' = match current_dir () with
    | None   -> p
    | Some d -> Fpath.(d // p)
    in
    let _ = show ~color:`Green "rm %a" Fpath.pp p' in
    OS.Path.delete ~recurse:true p
  )

let write_file ~dry_run p v =
  if not dry_run then OS.File.write p v
  else show "write %a" Fpath.pp p

let read_file ~dry_run p =
  if not dry_run then OS.File.read p
  else
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
      let _ = show ~color:`Green "chdir %a" Fpath.pp dir in
      OS.Dir.with_current dir f x
  | _ ->
      let _ = show "chdir %a" Fpath.pp dir in
      Ok (f x)

let file_must_exist ~dry_run f =
  if not dry_run then OS.File.must_exist f
  else
  let _ = show "must exists %a" Fpath.pp f in
  Ok f
