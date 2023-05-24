(*
 * Copyright (c) 2021 Magnus Skjegstad
 * Copyright (c) 2021 Thomas Gazagnaire <thomas@gazagnaire.org>
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

type list_type = Ordered of int * char | Bullet of char

type inline =
  | Concat of inline list
  | Text of string
  | Emph of inline
  | Strong of inline
  | Code of string
  | Hard_break
  | Soft_break
  | Link of link
  | Image of link
  | Html of string

and link = { label : inline; destination : string; title : string option }

(* The subset of mardown supported for work items *)
type t =
  | Paragraph of inline
  | List of list_type * t list list
  | Blockquote of t list
  | Code_block of string * string
  | Title of int * string

(* Dump contents *)

let dump_list_type ppf = function
  | Ordered (d, c) -> Fmt.pf ppf "Ordered (%d, %c)" d c
  | Bullet c -> Fmt.pf ppf "Bullet %c" c

let rec dump_inline ppf = function
  | Concat c -> Fmt.pf ppf "Concat %a" (Fmt.Dump.list dump_inline) c
  | Text s -> Fmt.pf ppf "Text %S" s
  | Emph e -> Fmt.pf ppf "Emph (%a)" dump_inline e
  | Strong e -> Fmt.pf ppf "Strong (%a)" dump_inline e
  | Code s -> Fmt.pf ppf "Code %S" s
  | Hard_break -> Fmt.pf ppf "Hard_break"
  | Soft_break -> Fmt.pf ppf "Soft_break"
  | Link l -> Fmt.pf ppf "Link %a" dump_link l
  | Image l -> Fmt.pf ppf "Image %a" dump_link l
  | Html s -> Fmt.pf ppf "Html %S" s

and dump_link ppf t =
  let open Fmt.Dump in
  record
    [
      field "label" (fun x -> x.label) dump_inline;
      field "destination" (fun x -> x.destination) string;
      field "title" (fun x -> x.title) (option string);
    ]
    ppf t

let rec dump ppf = function
  | Paragraph t -> Fmt.pf ppf "Paragraph (%a)" dump_inline t
  | List (x, y) ->
      Fmt.pf ppf "List (%a, %a)" dump_list_type x Fmt.Dump.(list (list dump)) y
  | Blockquote l -> Fmt.pf ppf "Blockquote %a" Fmt.(Dump.list dump) l
  | Code_block (x, y) -> Fmt.pf ppf "Code_block (%S, %S)" x y
  | Title (n, x) -> Fmt.pf ppf "Title (%d, %S)" n x

(* Pretty-print contents *)

open Printer

let rec pp_inline ppf = function
  | Concat c -> list ~sep:nop pp_inline ppf c
  | Text s -> string ppf s
  | Emph e ->
      string ppf "*";
      pp_inline ppf e;
      string ppf "*"
  | Strong e ->
      string ppf "**";
      pp_inline ppf e;
      string ppf "**"
  | Code s ->
      string ppf "`";
      string ppf s;
      string ppf "`"
  | Hard_break ->
      newline ppf ();
      newline ppf ()
  | Soft_break -> newline ppf ()
  | Link l ->
      string ppf "[";
      pp_inline ppf l.label;
      string ppf "](";
      string ppf l.destination;
      string ppf ")"
  | Image l ->
      string ppf "![";
      pp_inline ppf l.label;
      string ppf "](";
      string ppf l.destination;
      string ppf ")"
  | Html s -> string ppf s

let rec insert_breaks_between_paragraph = function
  | [] -> []
  | (Paragraph _ as h) :: (Paragraph _ :: _ as t) ->
      h :: Paragraph (Concat []) :: insert_breaks_between_paragraph t
  | h :: t -> h :: insert_breaks_between_paragraph t

let rec pp ppf = function
  | Paragraph t -> pp_inline ppf t
  | List (Ordered (i, c), y) ->
      list ~sep:nop
        (fun ppf e ->
          let e = insert_breaks_between_paragraph e in
          int ppf i;
          char ppf c;
          char ppf ' ';
          nest 2 (list ~sep:newline pp) ppf e)
        ppf y
  | List (Bullet c, y) ->
      list ~sep:newline
        (fun ppf e ->
          let e = insert_breaks_between_paragraph e in
          char ppf c;
          char ppf ' ';
          nest 2 (list ~sep:newline pp) ppf e)
        ppf y
  | Blockquote l ->
      string ppf "> ";
      List.iter (pp ppf) l
  | Code_block (lang, code) ->
      string ppf "```";
      string ppf lang;
      newline ppf ();
      string ppf code;
      string ppf "```"
  | Title (lvl, str) ->
      string ppf (String.make lvl '#');
      char ppf ' ';
      string ppf str
