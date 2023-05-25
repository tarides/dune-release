(*
 * Copyright (c) 2021 Patrick Ferris <pf341@patricoferris.com>
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

type date = CalendarLib.Date.t
(** A single date *)

type t
(** A specific range within the year *)

val week : t -> int
(** [week t] gets the week from [t] *)

val month : t -> int
(** [week t] gets the week from [t] *)

val weeks : t -> int list
(** [to_weeks] returns the list of weeks in the calendar range [t]. *)

val year : t -> int
(** [year t] gets the year from [t] *)

val of_week : ?year:int -> int -> t
(** [of_week ?year week] generates a [t] for ISO8601 week staring on the Monday
    and ending on the Sunday *)

val of_week_range : ?year:int -> int * int -> t
(** [of_week_range ?year (first, last)] return the range between the two weeks
    [first] and [last] inclusive of the final week (for a given optional
    [year]). *)

val of_month : ?year:int -> int -> t
(** [of_month ?year month] generates a [t] for the [month] staring on the first
    day of the month and ending on the last *)

val range : t -> date * date
(** [range t] gives the underlying start and end dates for [t] *)

val to_iso8601 : t -> string * string
(** [to_iso8601 t] converts [t] to the ISO8601 format *)

val to_gitlab : t -> string * string
(** [to_gitlab t] converts [t] to Gitlab API format (e.g. 2021-12-29) *)
