module F = Filter
open Okra

type item = {
  id : string;
  year : int;
  month : int;
  week : int;
  user : string;
  days : Time.t;
}

type t = (string, item) Hashtbl.t

let ( let* ) = Result.bind

let month_of_week ~year week =
  let* cal = Calendar.of_week ~year week in
  Ok (Calendar.month cal)

let ignore_sections =
  [
    "Projects";
    "Projects:";
    "OKR Updates";
    "Meetings etc:";
    "Meetings, etc.";
    "Issue and blockers (optional)";
    "Issue and blockers";
    "This Week";
    "Next week";
    "Other";
    "Others";
    "Activity";
    "Activity (move these items to last week)";
  ]

let match_user users =
  match users with
  | None -> fun _ -> true
  | Some us ->
      let us = List.map String.lowercase_ascii us in
      fun u -> List.mem (String.lowercase_ascii u) us

let match_ids ids =
  match ids with
  | None -> fun _ -> true
  | Some ids ->
      let ids = List.map (fun id -> (Column.Id, id)) ids in
      fun u -> F.eval ~get:(function Id -> u | _ -> assert false) ids

let of_markdown ?(acc = Hashtbl.create 13) ~path ~year ~week ~users ~ids ~lint s
    =
  let md = Omd.of_channel s in
  let okrs, parser_warnings =
    Parser.of_markdown ~ignore_sections Parser.Engineer md
  in
  let* month = month_of_week ~year week in
  let report, kr_warnings = Report.of_krs okrs in
  let match_user = match_user users in
  let match_ids = match_ids ids in
  Report.iter
    (fun (kr : KR.t) ->
      let id =
        match kr.kind with
        | Meta m -> Fmt.str "%a" KR.Meta.pp m
        | Work kr -> (
            match kr.id with
            | No_KR -> Fmt.str "(%s)" kr.title
            | New_KR -> Fmt.str "(new: %s)" kr.title
            | _ -> Fmt.str "%a" KR.Work.Id.pp kr.id)
      in
      if match_ids id then
        Hashtbl.iter
          (fun user days ->
            if match_user user then
              Hashtbl.add acc id { id; year; month; week; user; days })
          kr.time_per_engineer)
    report;
  if lint then (
    List.iter
      (fun e ->
        Logs.warn (fun l ->
            l "Cannot parse %s: %a" path Parser.Warning.pp_short e))
      parser_warnings;
    let pp ppf = function
      | #KR.Error.t as e -> KR.Error.pp_short ppf e
      | #KR.Warning.t as w -> KR.Warning.pp_short ppf w
    in
    List.iter (fun e -> Logs.warn (fun l -> l "%a" pp e)) kr_warnings);
  Ok acc

let csv_headers = [ "Id"; "Year"; "Month"; "Week"; "User"; "Days" ]

let rows t =
  let result = ref [] in
  Hashtbl.iter
    (fun _ i ->
      result :=
        [
          i.id;
          Fmt.str "%d" i.year;
          Fmt.str "%02d" i.month;
          Fmt.str "%02d" i.week;
          Fmt.str "%s" i.user;
          Fmt.str "%.1f" i.days.Time.data;
        ]
        :: !result)
    t;
  !result

let of_row x =
  if x = csv_headers then `Skip
  else
    match x with
    | [ id; year; month; week; user; days ] ->
        let i = int_of_string in
        let f x = Time.days @@ float_of_string x in
        `Row
          {
            id;
            year = i year;
            month = i month;
            week = i week;
            user;
            days = f days;
          }
    | [] | [ "" ] -> `Skip
    | _ -> Fmt.failwith "invalid row: %a" Fmt.Dump.(list string) x

let to_csv oc t =
  let rows = rows t in
  let out = Csv.to_channel ~quote_all:true oc in
  Csv.output_all out (csv_headers :: rows);
  Csv.close_out out

let of_csv ~years ~weeks ~users ~ids s =
  let weeks = Weeks.to_ints weeks in
  let input = Csv.of_channel s in
  let csv = Csv.input_all input in
  let t = Hashtbl.create 13 in
  let match_user = match_user users in
  let match_ids = match_ids ids in
  List.iter
    (fun x ->
      match of_row x with
      | `Skip -> ()
      | `Row x ->
          if
            List.mem x.year years && List.mem x.week weeks && match_user x.user
            && match_ids x.id
          then Hashtbl.add t x.id x)
    csv;
  t
