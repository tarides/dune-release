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

let of_markdown ?(acc = Hashtbl.create 13) ~year ~week s =
  let md = Omd.of_string s in
  let okrs = Parser.of_markdown md in
  let month = month_of_week ~year week in
  let report = Report.of_krs okrs in
  Report.iter
    (fun (kr : KR.t) ->
      let id = Fmt.str "%a" pp_id kr.id in
      Hashtbl.iter
        (fun user days ->
          Hashtbl.add acc id { id; year; month; week; user; days })
        kr.time_per_engineer)
    report;
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

let to_csv t =
  let rows = rows t in
  let buffer = Buffer.create 10 in
  let out = Csv.to_buffer ~quote_all:true buffer in
  Csv.output_all out (csv_headers :: rows);
  Csv.close_out out;
  Buffer.contents buffer
