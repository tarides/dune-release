(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Rresult
open Astring

(* Watermarks *)

type watermark =
  string *
  [ `String of string
  | `Name
  | `Version
  | `Version_num
  | `Vcs of [ `Commit_id ]
  | `Opam of Fpath.t option * string * string ]

let opam_fields ~dry_run file =
  (Opam.File.fields ~dry_run file)
  |> R.reword_error_msg ~replace:true (fun msg -> R.msgf "Watermarks: %s" msg)
  |> Logs.on_error_msg ~level:Logs.Warning ~use:(fun () -> String.Map.empty)

let opam_field =
  let opam_memo = ref Fpath.Map.empty in (* memoizes the opam files *)
  let rec opam_field ~dry_run file field = match Fpath.Map.find file !opam_memo with
  | None ->
      opam_memo := Fpath.Map.add file (opam_fields ~dry_run file) !opam_memo;
      opam_field ~dry_run file field
  | Some fields ->
      match String.Map.find field fields with
      | Some vs -> vs
      | None ->
          if not dry_run then
            Logs.warn
              (fun m -> m "file %a: opam field %S undefined or unsupported"
                  Fpath.pp file field);
          ["UNDEFINED"]
  in
  opam_field

let vcs_commit_id () =
  (Vcs.get () >>= fun repo -> Vcs.head ~dirty:true repo)
  |> R.reword_error_msg ~replace:true
    (fun msg -> R.msgf "Watermarks: VCS commit id determination: %s" msg)
  |> Logs.on_error_msg ~level:Logs.Warning ~use:(fun () -> "UNDEFINED")

let drop_initial_v version = match String.head version with
| Some ('v' | 'V') -> String.with_index_range ~first:1 version
| None | Some _ -> version

let define_watermarks ~dry_run ~name ~tag ~opam watermarks =
  let define (id, v) =
    let (id, v as def) = match v with
    | `String s -> (id, s)
    | `Version -> (id, tag)
    | `Version_num -> (id, drop_initial_v tag)
    | `Name -> (id, name)
    | `Vcs `Commit_id -> (id, vcs_commit_id ())
    | `Opam (file, field, sep) ->
        let file = match file with None -> opam | Some file -> file in
        (id, String.concat ~sep (opam_field ~dry_run file field))
    in
    Logs.info (fun m -> m "Watermark %s = %S" id v);
    def
  in
  List.map define watermarks

let with_parent_check op op_name file =
  let err_no_parent op_name file =
    Fmt.strf "%a: Cannot %s file, parent directory does not exist"
      Fpath.pp file op_name
  in
  (Bos.OS.Dir.must_exist (Fpath.parent file)
   >>= fun _ -> Ok (op (Fpath.to_string file)))
  |> R.reword_error @@ fun _ -> `Msg (err_no_parent op_name file)

let safe_open_out_bin = with_parent_check open_out_bin "write"

let write_subst file vars s = (* very ugly mister, too lazy to rewrite *)
  try
    let close oc = if file = Bos.OS.File.dash then () else close_out_noerr oc in
    (if file = Bos.OS.File.dash then Ok stdout
     else safe_open_out_bin file) >>= fun oc ->
    try
      let start = ref 0 in
      let last = ref 0 in
      let len = String.length s in
      while (!last < len - 4) do
        if not (s.[!last] = '%' && s.[!last + 1] = '%') then incr last else
        begin
          let start_subst = !last in
          let last_id = ref (!last + 2) in
          let stop = ref false in
          while (!last_id < len - 1 && not !stop) do
            if not (s.[!last_id] = '%' && s.[!last_id + 1] = '%') then begin
              if s.[!last_id] <> ' ' then (incr last_id) else
              (stop := true; last := !last_id)
            end else begin
              let id_start = start_subst + 2 in
              let id =
                String.with_range s ~first:(id_start) ~len:(!last_id - id_start)
              in
              try
                let subst = List.assoc id vars in
                output oc (Bytes.unsafe_of_string s)
                  !start (start_subst - !start);
                output_string oc subst;
                stop := true;
                start := !last_id + 2;
                last := !last_id + 2;
              with Not_found ->
                stop := true;
                last := !last_id
            end
          done;
          (* we exited the loop because we reached eof *)
          if not !stop then last := !last_id
        end
      done;
      output oc (Bytes.unsafe_of_string s) !start (len - !start);
      flush oc;
      close oc;
      Ok ()
    with exn -> close oc; raise exn
  with Sys_error e -> R.error_msgf "%a: %s" Fpath.pp file e

let watermark_file ws file =
  Bos.OS.File.read file >>= fun content ->
  write_subst file ws content >>= fun () ->
  Logs.info (fun m -> m "Watermarked %a" Fpath.pp file); Ok ()

let rec watermark_files ws = function
| [] -> Ok ()
| f :: fs -> watermark_file ws f >>= fun () -> watermark_files ws fs

(* Defaults *)

let default_watermarks =
  let space = " " in
  let comma = ", " in
  [ "NAME", `Name;
    "VERSION", `Version;
    "VERSION_NUM", `Version_num;
    "VCS_COMMIT_ID", `Vcs `Commit_id;
    "PKG_MAINTAINER", `Opam (None, "maintainer", comma);
    "PKG_AUTHORS", `Opam (None, "authors", comma);
    "PKG_HOMEPAGE", `Opam (None, "homepage", comma);
    "PKG_ISSUES", `Opam (None, "bug-reports", space);
    "PKG_DOC", `Opam (None, "doc", space);
    "PKG_LICENSE", `Opam (None, "license", comma);
    "PKG_REPO", `Opam (None, "dev-repo", space); ]

let default_files_to_watermark =
  let is_file f =
    Bos.OS.File.exists f |> Logs.on_error_msg ~use:(fun _ -> false)
  in
  let is_binary_ext ext =
    let module Set = Set.Make (String) in
    let exts =
      Set.(empty |>
           add ".flv" |> add ".gif" |> add ".ico" |> add ".jpeg" |>
           add ".jpg" |> add ".mov" |> add ".mp3" |> add ".mp4" |>
           add ".otf" |> add ".pdf" |> add ".png" |> add ".ttf" |>
           add ".woff")
    in
    Set.mem ext exts
  in
  let keep f = not (is_binary_ext @@ Fpath.get_ext f) && is_file f in
  fun () ->
    Vcs.get ()
    >>= fun repo -> Vcs.tracked_files repo
    >>= fun files -> Ok (List.filter keep files)

let default_massage () = Ok ()

let default_exclude_paths () =
  let l =
    List.map Fpath.v [
      ".git"; ".gitignore"; ".gitattributes"; ".hg"; ".hgignore"; "build";
      "Makefile"; "_build"
    ] in
  Ok l

(* Distribution *)

type t =
  { watermarks : watermark list;
    files_to_watermark : unit -> (Fpath.t list, R.msg) result;
    massage : unit -> (unit, R.msg) result;
    exclude_paths : unit -> (Fpath.t list, R.msg) result; }

let v
    ?(watermarks = default_watermarks)
    ?(files_to_watermark = default_files_to_watermark)
    ?(massage = fun () -> Ok ())
    ?(exclude_paths = default_exclude_paths) () =
  { watermarks; files_to_watermark; massage; exclude_paths }

let watermarks d = d.watermarks
let files_to_watermark d = d.files_to_watermark
let massage d = d.massage
let exclude_paths d = d.exclude_paths

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
