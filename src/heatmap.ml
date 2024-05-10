type row = {
  mutable total : Okra.Time.t;
  weeks : (int * int, Okra.Time.t) Hashtbl.t;
}

type t = (string, row) Hashtbl.t

let of_report t =
  let result = Hashtbl.create 13 in
  Hashtbl.iter
    (fun id (i : Report.item) ->
      let row =
        match Hashtbl.find_opt result id with
        | None ->
            let r = { total = Okra.Time.days 0.; weeks = Hashtbl.create 3 } in
            Hashtbl.add result id r;
            r
        | Some r -> r
      in
      let week =
        match Hashtbl.find_opt row.weeks (i.year, i.week) with
        | None -> Okra.Time.days 0.
        | Some i -> i
      in
      let open Okra.Time in
      let week = week +. i.days in
      Hashtbl.replace row.weeks (i.year, i.week) week;
      row.total <- row.total +. i.days)
    t;
  result

let opt f x y = match x with None -> Some y | Some x -> Some (f x y)

let start_date t id =
  match Hashtbl.find_opt t id with
  | None -> None
  | Some row -> Hashtbl.fold (fun k _ acc -> opt min acc k) row.weeks None

let end_date t id =
  match Hashtbl.find_opt t id with
  | None -> None
  | Some row -> Hashtbl.fold (fun k _ acc -> opt max acc k) row.weeks None

let pp_start_date ppf (year, week) =
  Fmt.string ppf
  @@
  match Okra.Calendar.of_week ~year week with
  | Ok date -> fst @@ Okra.Calendar.to_gitlab date
  | Error _ -> "<invalid>"

let pp_end_date ppf (year, week) =
  Fmt.string ppf
  @@
  match Okra.Calendar.of_week ~year week with
  | Ok date -> snd @@ Okra.Calendar.to_gitlab date
  | Error _ -> "<invalid>"

let pp_opt f ppf = function None -> Fmt.string ppf "?" | Some x -> f ppf x

let total (t : t) =
  let open Okra.Time in
  Hashtbl.fold (fun _ { total; _ } acc -> total +. acc) t (days 0.)

let pp ppf (t : t) =
  let ids = Hashtbl.fold (fun id { total; _ } acc -> (id, total) :: acc) t [] in
  let ids = List.sort (fun (_, a) (_, b) -> compare b a) ids in
  List.iter
    (fun (id, total) ->
      Fmt.pf ppf "%-12s [%.1f] %a => %a\n" id total.Okra.Time.data
        (pp_opt pp_start_date) (start_date t id) (pp_opt pp_end_date)
        (end_date t id))
    ids;
  Fmt.pf ppf "-----------\n";
  Fmt.pf ppf "%-12s [%.1f]\n" "Total" (total t).data

let to_csv (t : t) =
  let csv_headers = [ "ID"; "Days" ] in
  let ids =
    Hashtbl.fold
      (fun id { total; _ } acc -> (id, Fmt.str "%.1f" total.data) :: acc)
      t []
  in
  let rows = List.sort (fun (a, _) (b, _) -> String.compare a b) ids in
  let rows' = List.sort_uniq (fun (a, _) (b, _) -> String.compare a b) ids in
  assert (List.length rows = List.length rows');
  let rows = List.map (fun (a, b) -> [ a; b ]) rows in
  let buffer = Buffer.create 10 in
  let out = Csv.to_buffer ~quote_all:true buffer in
  Csv.output_all out (csv_headers :: rows);
  Csv.close_out out;
  Buffer.contents buffer
