open Okra

let pp_id ppf = function
  | KR.New_KR -> Fmt.pf ppf "New KR"
  | No_KR -> Fmt.pf ppf "No KR"
  | ID s -> Fmt.pf ppf "%s" s

type item = {
  id : string;
  year : int;
  month : int;
  week : int;
  user : string;
  days : float;
}

type t = (string, item) Hashtbl.t

let month_of_week ~year week =
  let cal = Calendar.of_week ~year week in
  Calendar.month cal

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

let pp_exn path ppf = function
  | Parser.No_time_found s ->
      Fmt.pf ppf "Cannot parse %s: no time found for entry `%s'." path s
  | Parser.Multiple_time_entries s ->
      Fmt.pf ppf "Cannot parse %s: multiple entries found for entry `%s'." path
        s
  | Parser.Invalid_time s ->
      Fmt.pf ppf "Cannot parse %s: invalid time for entry `%s'." path s
  | Parser.No_work_found _ -> ()
  | Parser.No_KR_ID_found s ->
      Fmt.pf ppf "Cannot parse %s: missing KR ID for `%s'." path s
  | Parser.No_project_found s ->
      Fmt.pf ppf "Cannot parse %s: missing project for `%s'." path s
  | Parser.Not_all_includes_accounted_for ss ->
      Fmt.pf ppf "Cannot parse %s: invalid time maths: %a." path
        Fmt.Dump.(list string)
        ss
  | e -> Fmt.pf ppf "Cannot parse %s: %a" path Fmt.exn e

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
      fun u -> Filter.eval ~get:(function Id -> u | _ -> assert false) ids

let of_markdown ?(acc = Hashtbl.create 13) ~path ~year ~week ~users ~ids ~lint s
    =
  let md = Omd.of_string s in
  let okrs, exns = Parser.of_markdown ~ignore_sections md in
  let month = month_of_week ~year week in
  let report, warms = Report.of_krs okrs in
  let match_user = match_user users in
  let match_ids = match_ids ids in
  Report.iter
    (fun (kr : KR.t) ->
      let id =
        match kr.id with
        | No_KR -> Fmt.str "(%s)" kr.title
        | New_KR -> Fmt.str "(new: %s)" kr.title
        | _ -> Fmt.str "%a" pp_id kr.id
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
        let s = String.trim (Fmt.str "%a" (pp_exn path) e) in
        if s <> "" then Logs.warn (fun l -> l "%s" s))
      exns;
    List.iter (fun s -> Logs.warn (fun l -> l "%s" s)) warms);
  acc

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
          Fmt.str "%.1f" i.days;
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
        let f = float_of_string in
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

let to_csv t =
  let rows = rows t in
  let buffer = Buffer.create 10 in
  let out = Csv.to_buffer ~quote_all:true buffer in
  Csv.output_all out (csv_headers :: rows);
  Csv.close_out out;
  Buffer.contents buffer

let of_csv ~years ~weeks ~users ~ids s =
  let weeks = Weeks.to_ints weeks in
  let input = Csv.of_string s in
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
