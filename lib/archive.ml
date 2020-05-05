(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup
module Sbytes = Stdext.Sbytes

(* Ustar archives *)

module Tar = struct
  let empty = []

  (* Header.

     See http://pubs.opengroup.org/onlinepubs/9699919799/utilities/\
         pax.html#tag_20_92_13_06 *)

  let to_unix_path_string =
    if Fpath.dir_sep = "/" then Fpath.to_string
    else fun f -> String.concat ~sep:"/" (Fpath.segs f)

  let set_filename h f =
    let s = to_unix_path_string f in
    let error = strf "%a: file name too long" Fpath.pp f in
    let blit a b c d e =
      R.reword_error (fun _ -> R.msg error) (Sbytes.blit_string a b c d e)
    in
    match String.length s with
    | n when n <= 100 -> blit s 0 h 0 (String.length s)
    | _ -> (
        match String.cut ~rev:true ~sep:"/" s with
        | Some (p, n) ->
            (* This could be made more clever by trying to find
               the slash nearest to the half string position. *)
            if String.length p > 155 || String.length n > 100 then
              R.error_msg error
            else
              blit n 0 h 0 (String.length n) >>= fun () ->
              blit p 0 h 345 (String.length p)
        | None -> R.error_msg error )

  let set_string off h s =
    R.reword_error
      (fun _ -> R.msgf "%S too long" s)
      (Sbytes.blit_string s 0 h off (String.length s))

  let set_octal field off len (* terminating NULL included *) h n =
    let octal = Printf.sprintf "%0*o" (len - 1) n in
    if String.length octal < len then
      R.reword_error
        (fun _ -> R.msgf "field %s: cannot set %d at offset %d" field n off)
        (Sbytes.blit_string octal 0 h off (String.length octal))
    else
      R.error_msg
        (strf "field %s: can't encode %d in %d-digit octal number" field
           (len - 1) n)

  let header_checksum h =
    let len = Bytes.length h in
    let rec loop acc i =
      if i > len then acc
      else loop (acc + (Char.to_int @@ Bytes.unsafe_get h i)) (i + 1)
    in
    loop 0 0

  let header fname mode mtime size typeflag =
    Sbytes.make 512 '\x00' >>= fun h ->
    set_filename h fname >>= fun () ->
    set_octal "mode" 100 8 h mode >>= fun () ->
    set_octal "owner" 108 8 h 0 >>= fun () ->
    set_octal "group" 116 8 h 0 >>= fun () ->
    set_octal "size" 124 12 h size >>= fun () ->
    set_octal "mtime" 136 12 h mtime >>= fun () ->
    set_string 148 h "        " (* Checksum *) >>= fun () ->
    set_string 156 h typeflag >>= fun () ->
    set_string 257 h "ustar" >>= fun () ->
    set_string 263 h "00" >>= fun () ->
    set_octal "devmajor" 329 8 h 0 >>= fun () ->
    set_octal "devminor" 329 8 h 0 >>= fun () ->
    let c = header_checksum h in
    set_octal "checksum" 148 9 (* not NULL terminated *) h c >>= fun () ->
    Ok (Bytes.unsafe_to_string h)

  (* Files *)

  let padding content =
    match String.length content mod 512 with
    | 0 -> ""
    | n -> Bytes.unsafe_to_string (Bytes.make (512 - n) '\x00')

  let add t fname ~mode ~mtime kind =
    let typeflag, size, data =
      match kind with
      | `Dir -> ("5", 0, [])
      | `File cont -> ("0", String.length cont, [ cont; padding cont ])
    in
    header fname mode mtime size typeflag >>| fun header ->
    List.rev_append data (header :: t)

  (* Encode *)

  let to_string t =
    let end_of_file = Bytes.unsafe_to_string (Bytes.make 1024 '\x00') in
    String.concat (List.rev (end_of_file :: t))
end

let path_set_of_dir dir ~exclude_paths =
  let add_prefix p acc = Fpath.(Set.add (dir // p) acc) in
  let exclude_paths = Fpath.Set.(fold add_prefix exclude_paths empty) in
  let not_excluded p = Ok (not (Fpath.Set.mem p exclude_paths)) in
  let traverse = `Sat not_excluded in
  let elements = `Sat not_excluded in
  let err _ e = e in
  OS.Dir.fold_contents ~dotfiles:true ~err ~elements ~traverse Fpath.Set.add
    Fpath.Set.empty dir

let tar dir ~exclude_paths ~root ~mtime =
  let tar_add file tar =
    let fname =
      match Fpath.rem_prefix dir file with
      | None -> assert false
      | Some file -> Fpath.(root // file)
    in
    Logs.info (fun m -> m "Archiving %a" Fpath.pp fname);
    tar >>= fun tar ->
    OS.Dir.exists file >>= function
    | true -> Tar.add tar fname ~mode:0o775 ~mtime `Dir
    | false ->
        OS.Path.Mode.get file >>= fun mode ->
        OS.File.read file >>= fun contents ->
        let mode = if 0o100 land mode > 0 then 0o775 else 0o664 in
        Tar.add tar fname ~mode ~mtime (`File contents)
  in
  path_set_of_dir dir ~exclude_paths >>= fun fset ->
  Fpath.Set.fold tar_add fset (Ok Tar.empty) >>| fun tar -> Tar.to_string tar

(* Bzip2 compression and unarchiving *)

let bzip2_cmd = OS.Env.(value "DUNE_RELEASE_BZIP2" cmd ~absent:(Cmd.v "bzip2"))

let ensure_bzip2 () = OS.Cmd.must_exist bzip2_cmd >>| fun _ -> ()

let bzip2 ~dry_run ?force ~dst s =
  Sos.run_io ~dry_run ?force ~default:() bzip2_cmd (OS.Cmd.in_string s)
    (OS.Cmd.to_file dst)

let tar_cmd = OS.Env.(value "DUNE_RELEASE_TAR" cmd ~absent:(Cmd.v "tar"))

let untbz ~dry_run ?(clean = false) ar =
  let clean_dir dir =
    OS.Dir.exists dir >>= function
    | true when clean -> Sos.delete_dir ~dry_run ~force:true dir
    | _ -> Ok ()
  in
  let archive_dir, ar = Fpath.split_base ar in
  let unarchive ar =
    let dir = Fpath.rem_ext ar in
    OS.Cmd.must_exist tar_cmd >>= fun _ ->
    clean_dir dir >>= fun () ->
    OS.File.exists ar >>= fun force ->
    Sos.run ~dry_run ~force Cmd.(tar_cmd % "-xjf" % p ar) >>= fun () ->
    Ok Fpath.(archive_dir // dir)
  in
  R.join @@ Sos.with_dir ~dry_run archive_dir unarchive ar

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
