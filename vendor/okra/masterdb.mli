(*
 * Copyright (c) 2021 Magnus Skjegstad <magnus@skjegstad.com>
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

exception Missing_ID of int * string
exception Duplicate_ID of int * string
exception Missing_objective of int * string
exception Missing_project of int * string
exception Missing_title of int * string
exception KR_not_found of string

type cat_t = Commercial | Community

type status_t =
  | Active
  | Dropped
  | Complete
  | Scheduled
  | Unscheduled
  | Wontfix

type elt_t = private {
  id : string;
  printable_id : string;
  title : string;
  objective : string;
  project : string;
  schedule : string option;
  lead : string;
  team : string;
  category : string;
  links : string option;
  reports : string list;
  status : status_t option;
}

type t = (string, elt_t) Hashtbl.t

val string_of_status : status_t -> string
val load_csv : ?separator:char -> string -> t
val find_kr_opt : t -> string -> elt_t option
val find_kr : t -> string -> elt_t
val find_title_opt : t -> string -> elt_t option
val find_krs_for_teams : t -> string list -> elt_t list
val find_krs_for_reports : t -> string list -> elt_t list
val find_krs_for_categories : t -> string list -> elt_t list
val has_kr : t -> string -> bool
