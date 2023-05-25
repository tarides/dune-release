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

module Cal = CalendarLib.Calendar

type date = Cal.Date.t
type t = { from : date; to_ : date }

let week t = Cal.Date.week t.from (* ISO compliant? *)
let month t = Cal.Date.month t.from |> Cal.Date.int_of_month
let year t = Cal.Date.year t.from
let day = 60. *. 60. *. 24.
let now () = Cal.now () |> Cal.to_date

let weeks { from; to_ } =
  let result = ref [] in
  if Cal.Date.year from <> Cal.Date.year to_ then
    failwith "invalid calendar range";
  for week = Cal.Date.week from to Cal.Date.week to_ do
    result := week :: !result
  done;
  List.rev !result

(* ISO8601 compliant:
   https://en.wikipedia.org/wiki/ISO_week_date#Calculating_an_ordinal_or_month_date_from_a_week_date *)
let monday_of_week week year =
  let fourth =
    Cal.Date.make year 1 4 |> Cal.Date.day_of_week |> Cal.Date.int_of_day
  in
  let monday = Cal.Date.int_of_day Cal.Mon in
  let d = (week * 7) + monday - (fourth + 3) in
  match d with
  | d when d < 1 ->
      let prev = year - 1 in
      let doy = d + Cal.Date.days_in_year prev in
      Cal.Date.from_day_of_year prev doy
  | d when d > Cal.Date.days_in_year year ->
      let doy = d - Cal.Date.days_in_year year in
      Cal.Date.from_day_of_year year doy
  | d -> Cal.Date.from_day_of_year year d

let of_week =
  let six_days = Cal.Date.Period.make 0 0 6 in
  fun ?year week ->
    let year = Option.value ~default:(now () |> Cal.Date.year) year in
    let monday = monday_of_week week year in
    { from = monday; to_ = Cal.Date.add monday six_days }

let of_week_range ?year (first, last) =
  let { from; to_ = _ } = of_week ?year first in
  let { from = _; to_ } = of_week ?year last in
  { from; to_ }

let of_month ?year month =
  let year = Option.value ~default:(now () |> Cal.Date.year) year in
  let from = Cal.Date.lmake ~year ~month ~day:1 () in
  let days = Cal.Date.days_in_month from in
  let to_ = Cal.Date.add from @@ Cal.Date.Period.day (days - 1) in
  { from; to_ }

let range { from; to_ } = (from, to_)

let float_to_8601 t =
  let open Unix in
  let t = gmtime t in
  Printf.sprintf "%04d-%02d-%02dT%02d:%02d:%02dZ" (t.tm_year + 1900)
    (t.tm_mon + 1) t.tm_mday t.tm_hour t.tm_min t.tm_sec

let to_iso8601 t =
  (* We store the dates, not the times as well so we add the extra day minus one
     second *)
  ( Cal.Date.to_unixfloat t.from |> float_to_8601,
    Cal.Date.to_unixfloat t.to_ +. day -. 1. |> float_to_8601 )

let format_gitlab f = CalendarLib.Printer.Date.fprint "%0Y-%0m-%0d" f

let to_gitlab t =
  let from, to_ = range t in
  (* Seems the Gitlab API is not inclusive of the lower bound day ? *)
  let day_before = Cal.Date.(prev from `Day) in
  (Fmt.str "%a" format_gitlab day_before, Fmt.str "%a" format_gitlab to_)
