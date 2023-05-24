(*
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

type ppf
type 'a t = ppf -> 'a -> unit

val int : int t
val char : char t
val string : string t
val newline : unit t
val nest : int -> 'a t -> 'a t
val list : ?sep:unit t -> 'a t -> 'a list t
val sep : string -> unit t
val nop : unit t
val ( ++ ) : 'a t -> 'a t -> 'a t

(** Outputs *)

val to_string : 'a t -> 'a -> string
val to_channel : out_channel -> 'a t -> 'a -> unit
val to_stdout : 'a t -> 'a -> unit
