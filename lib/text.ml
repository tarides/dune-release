(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup

type flavour = [ `Markdown | `Asciidoc ]

let flavour_of_fpath f =
  match String.Ascii.lowercase (Fpath.get_ext f) with
  | ".md" -> Some `Markdown
  | ".asciidoc" | ".adoc" -> Some `Asciidoc
  | _ -> None

let rec drop_blanks = function "" :: ls -> drop_blanks ls | ls -> ls

let last_line = function [] -> None | l :: _ -> Some l

(* Detecting headers *)

let simple_header hchar l before rest =
  match String.(length @@ take ~sat:(Char.equal hchar) l) with
  | 0 -> None
  | n -> Some (n, l, before, rest)

let underline_header n uchar l before rest =
  let is_underline_header uchar l =
    String.(length @@ take ~sat:(Char.equal uchar) l) >= 2
  in
  if not (is_underline_header uchar l) then None
  else
    match last_line before with
    | None -> None
    | Some t -> Some (n, strf "%s\n%s" t l, List.tl before, rest)

let rec find_markdown_header before = function
  | [] -> None
  | l :: ls -> (
      match simple_header '#' l before ls with
      | Some _ as h -> h
      | None -> (
          match underline_header 1 '=' l before ls with
          | Some _ as h -> h
          | None -> (
              match underline_header 2 '-' l before ls with
              | Some _ as h -> h
              | None -> find_markdown_header (l :: before) ls)))

let rec find_asciidoc_header before = function
  | [] -> None
  | l :: ls -> (
      match simple_header '=' l before ls with
      | Some _ as h -> h
      | None -> (
          match underline_header 1 '-' l before ls with
          | Some _ as h -> h
          | None -> (
              match underline_header 2 '~' l before ls with
              | Some _ as h -> h
              | None -> (
                  match underline_header 3 '^' l before ls with
                  | Some _ as h -> h
                  | None -> (
                      match underline_header 4 '+' l before ls with
                      | Some _ as h -> h
                      | None -> find_asciidoc_header (l :: before) ls)))))

let head find_header text =
  let lines = String.cuts ~sep:"\n" text in
  let ret h acc =
    let contents = String.concat ~sep:"\n" (List.rev @@ drop_blanks acc) in
    Some (h, contents)
  in
  match find_header [] lines with
  | None -> None
  | Some (n, first, _ (* discard *), rest) ->
      let rec loop acc rest =
        match find_header acc rest with
        | None -> ret first (List.rev_append rest acc)
        | Some (n', h, before, rest) ->
            if n' > n then loop (h :: before) rest else ret first before
      in
      loop [] rest

let head ?(flavour = `Markdown) text =
  match flavour with
  | `Markdown -> head find_markdown_header text
  | `Asciidoc -> head find_asciidoc_header text

let header_title ?(flavour = `Markdown) h =
  match String.cuts ~sep:"\n" h with
  | [ h ] -> (
      match flavour with
      | `Markdown -> String.(trim @@ drop ~sat:(Char.equal '#') h)
      | `Asciidoc -> String.(trim @@ drop ~sat:(Char.equal '=') h))
  | h :: _ -> h (* underline headers *)
  | [] -> assert false

(* Toy change log parsing *)

let change_log_last_entry ?flavour text =
  match head ?flavour text with
  | None -> None
  | Some (h, changes) -> (
      let title = header_title ?flavour h in
      match String.take ~sat:Char.Ascii.is_graphic title with
      | "" ->
          Logs.app (fun m -> m "%S %S" h changes);
          None
      | version ->
          let changes =
            match
              String.cuts ~sep:"\n" changes
              |> List.map (String.drop ~rev:true ~sat:Char.Ascii.is_white)
            with
            | [] -> "(none)"
            | "" :: lines -> String.concat ~sep:"\n" lines
            | lines -> String.concat ~sep:"\n" lines
          in
          Some (version, (h, changes)))

let change_log_file_last_entry file =
  let flavour = flavour_of_fpath file in
  OS.File.read file >>= fun text ->
  match change_log_last_entry ?flavour text with
  | None -> R.error_msgf "%a: Could not parse change log." Fpath.pp file
  | Some (version, (header, changes)) -> Ok (version, (header, changes))

let github_issue =
  Re.(
    compile
    @@ seq [ group (compl [ alnum ]); group (seq [ char '#'; rep1 digit ]) ])

let rewrite_github_refs ~user ~repo msg =
  Re.replace github_issue msg ~f:(fun s ->
      let x = Re.Group.get s 1 in
      let y = Re.Group.get s 2 in
      Fmt.strf "%s%s/%s%s" x user repo y)

(* Toy URI parsing *)

let split_uri ?(rel = false) uri =
  match String.(cut ~sep:"//" (trim uri)) with
  | None -> None
  | Some (scheme, rest) -> (
      match String.cut ~sep:"/" rest with
      | None -> Some (scheme, rest, "")
      | Some (host, path) ->
          let path = if rel then path else "/" ^ path in
          Some (scheme, host, path))

(* Pretty-printers. *)

module Pp = struct
  let name = Fmt.(styled `Bold string)

  let version = Fmt.(styled `Cyan string)

  let commit = Fmt.(styled `Yellow string)

  let dirty = Fmt.(styled_unit `Red "dirty")

  let path fmt path = Fmt.(styled `Bold Fpath.pp) fmt (Fpath.normalize path)

  let url = Fmt.(styled `Underline string)

  let status ppf = function
    | `Ok -> Fmt.(brackets @@ styled_unit `Green " OK ") ppf ()
    | `Fail -> Fmt.(brackets @@ styled_unit `Red "FAIL") ppf ()

  let maybe_draft ppf (draft, s) =
    if draft then Fmt.(styled `Bold string) ppf "draft ";
    Fmt.string ppf s
end

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
