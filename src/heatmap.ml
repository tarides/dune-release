type row = (int * int, float) Hashtbl.t
type t = (string, row) Hashtbl.t

let of_report t =
  let result = Hashtbl.create 13 in
  Hashtbl.iter
    (fun id (i : Report.item) ->
      let row =
        match Hashtbl.find_opt result id with
        | None ->
            let r = Hashtbl.create 3 in
            Hashtbl.add result id r;
            r
        | Some r -> r
      in
      let total =
        match Hashtbl.find_opt row (i.year, i.week) with
        | None -> 0.
        | Some i -> i
      in
      let total = total +. i.days in
      Hashtbl.replace row (i.year, i.week) total)
    t;
  result

let opt f x y = match x with None -> Some y | Some x -> Some (f x y)

let start_date t id =
  match Hashtbl.find_opt t id with
  | None -> None
  | Some row ->
      assert (Hashtbl.length row > 0);
      Hashtbl.fold (fun k _ acc -> opt min acc k) row None

let end_date t id =
  match Hashtbl.find_opt t id with
  | None -> None
  | Some row ->
      assert (Hashtbl.length row > 0);
      Hashtbl.fold (fun k _ acc -> opt max acc k) row None

let pp_start_date ppf = function
  | None -> Fmt.string ppf "?"
  | Some (year, week) ->
      let date = Okra.Calendar.of_week ~year week in
      let from, _ = Okra.Calendar.to_gitlab date in
      Fmt.string ppf from

let pp_end_date ppf = function
  | None -> Fmt.string ppf "?"
  | Some (year, week) ->
      let date = Okra.Calendar.of_week ~year week in
      let _, to_ = Okra.Calendar.to_gitlab date in
      Fmt.string ppf to_

let pp ppf t =
  Hashtbl.iter
    (fun id _ ->
      Fmt.pf ppf "%-12s: %a => %a\n" id pp_start_date (start_date t id)
        pp_end_date (end_date t id))
    t
