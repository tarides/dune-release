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
type ppf = { mutable newline : bool; mutable indent : int; buf : Buffer.t }
type 'a t = ppf -> 'a -> unit

let ppf () = { newline = true; indent = 0; buf = Buffer.create 1024 }
let spaces = String.make 200 ' '

(* add indentation if needed *)
let indent t =
  if t.newline then (
    Buffer.add_substring t.buf spaces 0 t.indent;
    t.newline <- false)

(* should not contain any newline *)
let unsafe_string t s =
  if s <> "" then (
    indent t;
    Buffer.add_string t.buf s)

let newline t () =
  Buffer.add_char t.buf '\n';
  t.newline <- true

let char t c =
  indent t;
  Buffer.add_char t.buf c;
  t.newline <- false

let int t i = unsafe_string t (string_of_int i)

let string t s =
  match List.rev (String.split_on_char '\n' s) with
  | [] -> ()
  | h :: r ->
      List.iter
        (fun line ->
          unsafe_string t line;
          newline t ())
        (List.rev r);
      unsafe_string t h

let iter ?sep:(pp_sep = newline) iter pp_elt t v =
  let is_first = ref true in
  let pp_elt v =
    if !is_first then is_first := false else pp_sep t ();
    pp_elt t v
  in
  iter pp_elt v

let ( ++ ) pp_x pp_y ppf i =
  pp_x ppf i;
  pp_y ppf i

let list ?sep pp_elt = iter ?sep List.iter pp_elt
let sep s t () = string t s
let nop _ _ = ()

let nest n pp_v t v =
  let i = t.indent in
  t.indent <- i + n;
  pp_v t v;
  t.indent <- i

let flush t =
  let s = Buffer.contents t.buf in
  t.newline <- true;
  t.indent <- 0;
  Buffer.clear t.buf;
  s

let to_string pp_v v =
  let ppf = ppf () in
  pp_v ppf v;
  flush ppf

let to_channel oc pp_v v =
  let s = to_string pp_v v in
  output_string oc s

let to_stdout pp_v v = to_channel stdout pp_v v
