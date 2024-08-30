module F = Filter
open Okra

type item = {
  id : string;
  year : int;
  month : int;
  week : int;
  days : Time.t;
  hours : Time.t;
  user : string;
  funder : string;
  team : string;
  category : string;
  objective : string;
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

let of_markdown ?(cards = []) ?(acc = Hashtbl.create 13) ~path ~year ~week
    ~users ~ids ~lint s =
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
      let get_card_field f =
        match List.find_opt (fun x -> Card.id x = id) cards with
        | Some c -> f c
        | None -> ""
      in
      if match_ids id then
        Hashtbl.iter
          (fun user days ->
            if match_user user then
              Hashtbl.add acc id
                {
                  id;
                  year;
                  month;
                  week;
                  days;
                  (* TODO *) hours = Time.nil;
                  user;
                  funder = get_card_field Card.funder;
                  team = get_card_field Card.team;
                  category = get_card_field Card.category;
                  objective = get_card_field Card.title;
                })
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

let csv_headers =
  [
    "Number";
    "Id";
    "Year";
    "Month";
    "Week";
    "Days";
    "Hours";
    "User";
    "Full Name";
    "Funder";
    "Entity Funder";
    "Objective";
    "Team";
    "Category";
  ]

let ( or ) x y = if x = 0 then y else x

let compare_items x y =
  Int.compare x.year y.year
  or String.compare x.user y.user
  or Int.compare x.month y.month
  or Int.compare x.week y.week or String.compare x.id y.id

let rows t =
  let todo_import_from_another_table _name = "" in
  Hashtbl.to_seq_values t |> List.of_seq |> List.sort compare_items
  |> List.map (fun i ->
         [
           todo_import_from_another_table "number";
           i.id;
           Fmt.str "%d" i.year;
           Fmt.str "%02d" i.month;
           Fmt.str "%02d" i.week;
           Fmt.str "%g" i.days.data;
           (* TODO: Fmt.str "%g" i.hours.data*)
           "";
           i.user;
           todo_import_from_another_table "full_name";
           i.funder;
           todo_import_from_another_table "entity_funder";
           i.objective;
           i.team;
           i.category;
         ])

let of_row header x =
  let time x =
    x |> Float.of_string_opt |> Option.map Time.days
    |> Option.value ~default:Time.nil
  in
  let x = Csv.Row.with_header x header in
  {
    id = Csv.Row.find x "Id";
    year = int_of_string @@ Csv.Row.find x "Year";
    month = int_of_string @@ Csv.Row.find x "Month";
    week = int_of_string @@ Csv.Row.find x "Week";
    days = time @@ Csv.Row.find x "Days";
    hours = time @@ Csv.Row.find x "Hours";
    user = Csv.Row.find x "User";
    funder = Csv.Row.find x "Funder";
    team = Csv.Row.find x "Team";
    category = Csv.Row.find x "Category";
    objective = Csv.Row.find x "Objective";
  }

let to_csv oc t =
  let rows = rows t in
  let out = Csv.to_channel ~quote_all:true oc in
  Csv.output_all out (csv_headers :: rows);
  Csv.close_out out

let of_csv ~years ~weeks ~users ~ids s =
  let weeks = Weeks.to_ints weeks in
  let input = Csv.of_channel s in
  let csv = Csv.Rows.input_all input in
  let t = Hashtbl.create 13 in
  let match_user = match_user users in
  let match_ids = match_ids ids in
  let () =
    match csv with
    | [] -> ()
    | header :: data ->
        let header = Csv.Row.to_list header in
        List.iter
          (fun r ->
            match Csv.Row.to_list r with
            | [] | [ "" ] -> ()
            | _ ->
                let i = of_row header r in
                if
                  List.mem i.year years && List.mem i.week weeks
                  && match_user i.user && match_ids i.id
                then Hashtbl.add t i.id i)
          data
  in
  t
