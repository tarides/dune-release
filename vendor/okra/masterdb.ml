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

type elt_t = {
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

let status_of_string s =
  match String.uppercase_ascii s with
  | "ACTIVE" -> Some Active
  | "DROPPED" -> Some Dropped
  | "COMPLETE" -> Some Complete
  | "SCHEDULED" -> Some Scheduled
  | "UNSCHEDULED" -> Some Unscheduled
  | "WONTFIX" -> Some Wontfix
  | _ -> None

let string_of_status s =
  match s with
  | Active -> "Active"
  | Dropped -> "Dropped"
  | Complete -> "Complete"
  | Scheduled -> "Scheduled"
  | Unscheduled -> "Unscheduled"
  | Wontfix -> "Wontfix"

let empty_db = Hashtbl.create 13

let load_csv ?(separator = ',') f =
  let res = empty_db in
  let line = ref 1 in
  let ic = open_in f in
  try
    let rows = Csv.of_channel ~separator ~has_header:true ic in
    Csv.Rows.iter
      ~f:(fun row ->
        line := !line + 1;
        let find_and_trim col = Csv.Row.find row col |> String.trim in
        let find_and_trim_opt col =
          let v = find_and_trim col in
          if v <> "" then Some v else None
        in
        let find_and_trim_list col =
          match find_and_trim_opt col with
          | None -> []
          | Some s -> Str.split (Str.regexp "[ ,]+") s
        in
        let printable_id = find_and_trim "id" in
        let e =
          {
            id = String.uppercase_ascii printable_id;
            printable_id;
            title = find_and_trim "title";
            objective = find_and_trim "objective";
            project = find_and_trim "project";
            schedule = find_and_trim_opt "schedule";
            lead = find_and_trim "lead";
            team = find_and_trim "team";
            category = find_and_trim "category";
            reports = find_and_trim_list "reports";
            links = find_and_trim_opt "links";
            status = find_and_trim "status" |> status_of_string;
          }
        in
        if e.id = "" then
          raise (Missing_ID (!line, "A unique KR ID is required per line"));
        if Hashtbl.mem res e.id then
          raise
            (Duplicate_ID (!line, Fmt.str "KR ID \"%s\" is not unique." e.id));
        if e.title = "" then
          raise
            (Missing_title
               (!line, Fmt.str "KR ID \"%s\" does not have a title" e.id));
        if e.objective = "" then
          raise
            (Missing_objective
               ( !line,
                 Fmt.str "KR ID \"%s\" does is not part of an objective" e.id ));
        if e.project = "" then
          raise
            (Missing_project
               (!line, Fmt.str "KR ID \"%s\" does is not part of a project" e.id));
        Hashtbl.add res e.id e)
      rows;
    res
  with e ->
    close_in_noerr ic;
    raise e

let find_kr_opt t id = Hashtbl.find_opt t (id |> String.uppercase_ascii)

let find_kr t id =
  match find_kr_opt t id with None -> raise (KR_not_found id) | Some x -> x

let has_kr t id = Hashtbl.mem t (id |> String.uppercase_ascii)

let find_title_opt t title =
  let title_no_case = title |> String.uppercase_ascii |> String.trim in
  let okrs = Hashtbl.to_seq_values t |> List.of_seq in
  List.find_opt
    (fun kr ->
      kr.title |> String.uppercase_ascii |> String.trim = title_no_case)
    okrs

let filter_krs t f =
  let v = Hashtbl.to_seq_values t in
  List.of_seq (Seq.filter f v)

let find_krs_for_teams t teams =
  let teams = List.map String.uppercase_ascii teams in
  let p e = List.exists (String.equal (String.uppercase_ascii e.team)) teams in
  filter_krs t p

let find_krs_for_categories t categories =
  let categories = List.map String.uppercase_ascii categories in
  let p e =
    List.exists (String.equal (String.uppercase_ascii e.category)) categories
  in
  filter_krs t p

let find_krs_for_reports t reports =
  let reports = List.map String.uppercase_ascii reports in
  let p e =
    List.exists
      (fun report ->
        let report = String.uppercase_ascii report in
        List.exists (String.equal report) reports)
      e.reports
  in
  filter_krs t p
