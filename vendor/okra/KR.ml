(*
 * Copyright (c) 2021 Magnus Skjegstad <magnus@skjegstad.com>
 * Copyright (c) 2021 Thomas Gazagnaire <thomas@gazagnaire.org>
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

let src = Logs.Src.create "okra.KR"

module Log = (val Logs.src_log src : Logs.LOG)

type id = New_KR | No_KR | ID of string

let pp_id ppf = function
  | New_KR -> Fmt.pf ppf "New KR"
  | No_KR -> Fmt.pf ppf "No KR"
  | ID s -> Fmt.pf ppf "%s" s

type t = {
  counter : int;
  project : string;
  objective : string;
  title : string;
  id : id;
  time_entries : (string * float) list list;
  time_per_engineer : (string, float) Hashtbl.t;
  work : Item.t list list;
}

let counter =
  let c = ref 0 in
  fun () ->
    let i = !c in
    incr c;
    i

let v ~project ~objective ~title ~id ~time_entries work =
  let counter = counter () in
  (* Sum time per engineer *)
  let time_per_engineer =
    let tbl = Hashtbl.create 7 in
    List.iter
      (List.iter (fun (e, d) ->
           let d =
             match Hashtbl.find_opt tbl e with None -> d | Some x -> x +. d
           in
           Hashtbl.replace tbl e d))
      time_entries;
    tbl
  in
  {
    counter;
    project;
    objective;
    title;
    id;
    time_entries;
    time_per_engineer;
    work;
  }

let dump =
  let open Fmt.Dump in
  record
    [
      field "counter" (fun t -> t.counter) Fmt.int;
      field "project" (fun t -> t.project) string;
      field "objective" (fun t -> t.objective) string;
      field "title" (fun t -> t.title) string;
      field "id" (fun t -> t.id) pp_id;
      field "time_entries"
        (fun t -> t.time_entries)
        (list (list (pair string Fmt.float)));
      field "time_per_engineer"
        (fun t -> List.of_seq (Hashtbl.to_seq t.time_per_engineer))
        (list (pair string Fmt.float));
      field "work" (fun t -> t.work) (list (list Item.dump));
    ]

let compare_no_case x y =
  let x = String.uppercase_ascii x in
  let y = String.uppercase_ascii y in
  String.compare x y

let equal_id a b =
  match (a, b) with
  | New_KR, New_KR | No_KR, No_KR -> true
  | ID id1, ID id2 -> compare_no_case id1 id2 = 0
  | _ -> false

let merge x y =
  let counter = x.counter in
  let title =
    match (x.title, y.title) with
    | "", s | s, "" -> s
    | x, y ->
        if compare_no_case x y <> 0 then
          Log.warn (fun l -> l "Conflicting titles:\n- %S\n- %S" x y);
        x
  in
  let project =
    match (x.project, y.project) with
    | "", s | s, "" -> s
    | x, y ->
        if compare_no_case x y <> 0 then
          Log.warn (fun l ->
              l "KR %S appears in two projects:\n- %S\n- %S" title x y);
        x
  in
  let objective =
    match (x.objective, y.objective) with
    | "", s | s, "" -> s
    | x, y ->
        if compare_no_case x y <> 0 then
          Log.warn (fun l ->
              l "KR %S appears in two objectives:\n- %S\n- %S" title x y);
        x
  in
  let id =
    match (x.id, y.id) with
    | ID x, ID y ->
        assert (compare_no_case x y = 0);
        ID x
    | ID x, _ | _, ID x -> ID x
    | No_KR, No_KR -> No_KR
    | New_KR, New_KR -> New_KR
    | No_KR, New_KR | New_KR, No_KR ->
        Fmt.failwith
          "Mismatch between KR kinds. Same title was used with both No KR and \
           New KR. Title: %s"
          title
  in
  let time_entries = x.time_entries @ y.time_entries in
  let time_per_engineer =
    let t = Hashtbl.create 13 in
    Hashtbl.iter (fun k v -> Hashtbl.add t k v) x.time_per_engineer;
    Hashtbl.iter
      (fun k v ->
        match Hashtbl.find_opt t k with
        | None -> Hashtbl.replace t k v
        | Some v' -> Hashtbl.replace t k (v +. v'))
      y.time_per_engineer;
    t
  in
  let work = x.work @ y.work in
  {
    counter;
    project;
    objective;
    title;
    id;
    time_entries;
    time_per_engineer;
    work;
  }

let compare a b =
  match (a.id, b.id) with
  | ID a, ID b -> compare_no_case a b
  | _ -> compare_no_case a.title b.title

let string_of_days d =
  let d = floor (d *. 2.0) /. 2. in
  if d = 1. then "1 day"
  else if classify_float (fst (modf d)) = FP_zero then
    Printf.sprintf "%.0f days" d
  else Printf.sprintf "%.1f days" d

let make_engineer ~time (e, d) =
  if time then Printf.sprintf "@%s (%s)" e (string_of_days d)
  else Printf.sprintf "@%s" e

let make_engineers ~time entries =
  let entries = List.of_seq (Hashtbl.to_seq entries) in
  let entries = List.sort (fun (x, _) (y, _) -> String.compare x y) entries in
  let engineers = List.rev_map (make_engineer ~time) entries in
  match engineers with
  | [] -> []
  | e :: es ->
      let open Item in
      let lst =
        List.fold_left
          (fun acc engineer -> Text engineer :: Text ", " :: acc)
          [ Text e ] es
      in
      [ Paragraph (Concat lst) ]

let make_time_entries t =
  let aux (e, d) = Fmt.str "@%s (%s)" e (string_of_days d) in
  Item.[ Paragraph (Text (String.concat ", " (List.map aux t))) ]

let update_from_master_db t db =
  let update (orig_kr : t) (db_kr : Masterdb.elt_t option) =
    match db_kr with
    | None ->
        if orig_kr.id = New_KR then
          Log.warn (fun l -> l "KR ID not found for new KR %S" orig_kr.title);
        orig_kr
    | Some db_kr ->
        if orig_kr.id = No_KR then
          Log.warn (fun l ->
              l "KR ID updated from \"No KR\" to %S:\n- %S\n- %S" db_kr.id
                orig_kr.title db_kr.title);
        (match db_kr.status with
        | Some Active -> ()
        | Some s ->
            Log.warn (fun l ->
                l "Work logged on KR marked as %S: %S (%S)"
                  (Masterdb.string_of_status s)
                  db_kr.title db_kr.id)
        | None ->
            Log.warn (fun l ->
                l
                  "Work logged on KR with no status set, status should be \
                   Active: %S (%S)"
                  db_kr.title db_kr.id));
        {
          orig_kr with
          id = ID db_kr.printable_id;
          title = db_kr.title;
          objective = db_kr.objective;
          project = db_kr.project;
        }
  in

  match t.id with
  | ID id ->
      let db_kr = Masterdb.find_kr_opt db id in
      update t db_kr
  | _ ->
      let db_kr = Masterdb.find_title_opt db t.title in
      update t db_kr

let items ?(show_time = true) ?(show_time_calc = false) ?(show_engineers = true)
    kr =
  let open Item in
  let items =
    if not show_engineers then []
    else if show_time then
      if show_time_calc then
        (* show time calc + engineers *)
        [
          List (Bullet '+', List.map make_time_entries kr.time_entries);
          List (Bullet '=', [ make_engineers ~time:true kr.time_per_engineer ]);
        ]
      else make_engineers ~time:true kr.time_per_engineer
    else make_engineers ~time:false kr.time_per_engineer
  in
  [
    List
      ( Bullet '-',
        [
          [
            Paragraph (Text (Fmt.str "%s (%a)" kr.title pp_id kr.id));
            List (Bullet '-', items :: kr.work);
          ];
        ] );
  ]
