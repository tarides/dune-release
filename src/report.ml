open Okra

let pp_id ppf = function
  | KR.New_KR -> Fmt.pf ppf "New KR"
  | No_KR -> Fmt.pf ppf "No KR"
  | ID s -> Fmt.pf ppf "%s" s

let total_time (t : (string * float) list list) =
  List.fold_left (List.fold_left (fun acc (_, f) -> acc +. f)) 0. t

type item = { id : string; year : int; month : int; duration : float }
type t = (string, item) Hashtbl.t

let of_markdown ?(acc = Hashtbl.create 13) ~year ~month s =
  let md = Omd.of_string s in
  let okrs = Parser.of_markdown md in
  let report = Report.of_krs okrs in
  Report.iter
    (fun (kr : KR.t) ->
      let id = Fmt.str "%a" pp_id kr.id in
      let duration = total_time kr.time_entries in
      Hashtbl.add acc id { id; year; month; duration })
    report;
  acc

let csv_headers = [ "Id"; "Year"; "Month"; "Duration" ]

let rows t =
  let result = ref [] in
  Hashtbl.iter
    (fun _ i ->
      result :=
        [
          i.id;
          Fmt.str "%d" i.year;
          Fmt.str "%2d" i.month;
          Fmt.str "%.1f" i.duration;
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
