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

(** The subset of mardown supported for work items *)

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

type t =
  | Paragraph of inline
  | List of list_type * t list list
  | Blockquote of t list
  | Code_block of string * string
  | Title of int * string

val pp : t Printer.t
val pp_inline : inline Printer.t
val dump : t Fmt.t
val dump_inline : inline Fmt.t
