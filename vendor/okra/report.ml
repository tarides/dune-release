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

let src = Logs.Src.create "okra.report"

module Log = (val Logs.src_log src : Logs.LOG)

type krs = {
  (* KRs are indexed by ID *)
  ids : (string, KR.t) Hashtbl.t;
  (* New KRs do not have an ID, so they are indexed by title *)
  titles : (string, KR.t) Hashtbl.t;
}

let empty_krs () = { ids = Hashtbl.create 13; titles = Hashtbl.create 13 }

type objective = { name : string; krs : krs }
type project = { name : string; objectives : (string, objective) Hashtbl.t }

type t = {
  (* the list of all KRs *)
  all_krs : krs;
  (* that same list, but indexed by project *)
  projects : (string, project) Hashtbl.t;
}

let compare_no_case x y =
  String.compare (String.uppercase_ascii x) (String.uppercase_ascii y)

let find_no_case t k = Hashtbl.find_opt t (String.uppercase_ascii k)
let add_no_case t k v = Hashtbl.add t (String.uppercase_ascii k) v
let replace_no_case t k v = Hashtbl.replace t (String.uppercase_ascii k) v
let remove_no_case t k = Hashtbl.remove t (String.uppercase_ascii k)
let is_new_kr kr = kr.KR.id = New_KR
let is_no_kr kr = kr.KR.id = No_KR

let iter_krs f t =
  Hashtbl.iter (fun _ kr -> f kr) t.ids;
  Hashtbl.iter (fun _ kr -> if is_new_kr kr then f kr) t.titles

let iter_objective f t = iter_krs f t.krs
let skip _ _ = ()

let iter_project ?(objective = skip) f t =
  Hashtbl.iter
    (fun _ (o : objective) ->
      objective o.name o;
      iter_objective f o)
    t.objectives

let iter ?(project = skip) ?objective f t =
  Hashtbl.iter
    (fun _ (p : project) ->
      project p.name p;
      iter_project ?objective f p)
    t.projects

let krs t =
  let l = ref [] in
  iter_krs (fun x -> l := x :: !l) t.krs;
  List.rev !l

let all_krs t =
  let l = ref [] in
  iter_krs (fun x -> l := x :: !l) t.all_krs;
  List.rev !l

let new_krs t =
  let l = ref [] in
  iter_krs (fun x -> if is_new_kr x then l := x :: !l) t.all_krs;
  List.rev !l

let no_krs t =
  let l = ref [] in
  iter_krs (fun x -> if is_no_kr x then l := x :: !l) t.all_krs;
  List.rev !l

module Project = struct
  type t = project

  let name (t : project) = t.name
  let objectives t = Hashtbl.to_seq t.objectives |> Seq.map snd |> List.of_seq
  let find t s = find_no_case t.projects s

  let krs t =
    let l = ref [] in
    iter_project (fun x -> l := x :: !l) t;
    List.rev !l
end

module Objective = struct
  type t = objective

  let name (t : objective) = t.name
  let krs = krs
  let find t s = find_no_case t.objectives s

  let find_all t s =
    Hashtbl.fold
      (fun _ p acc ->
        match find p s with None -> acc | Some x -> (p, x) :: acc)
      t.projects []
end

let find t ?title ?id () =
  let l = ref [] in
  iter_krs
    (fun kr ->
      if Some kr.KR.title = title || Option.equal KR.equal_id (Some kr.KR.id) id
      then l := kr :: !l)
    t.all_krs;
  List.rev !l

let dump ppf t = Fmt.iter iter KR.dump ppf t

let compare_objectives (x : objective) (y : objective) =
  compare_no_case x.name y.name

let compare_projects (x : project) (y : project) = compare_no_case x.name y.name

let remove (t : t) (e : KR.t) =
  Log.debug (fun l -> l "Report.remove %a" KR.dump e);
  let remove t =
    remove_no_case t.titles e.title;
    match e.id with ID id -> remove_no_case t.ids id | _ -> ()
  in
  let () =
    match find_no_case t.projects e.project with
    | None -> ()
    | Some p -> (
        match find_no_case p.objectives e.objective with
        | None -> ()
        | Some o -> remove o.krs)
  in
  remove t.all_krs

let add ?okr_db (t : t) (e : KR.t) =
  Log.debug (fun l -> l "Report.add %a %a" dump t KR.dump e);

  (* replace e fields with master db lookup if possible *)
  let e =
    match okr_db with
    | None -> e (* no db *)
    | Some db -> KR.update_from_master_db e db
  in
  let existing_kr =
    match e.id with
    | No_KR | New_KR -> find_no_case t.all_krs.titles e.title
    | ID id -> (
        match find_no_case t.all_krs.ids id with
        | Some kr -> Some kr
        | None -> (
            match find_no_case t.all_krs.titles e.title with
            | Some kr when is_new_kr kr -> Some kr
            | Some kr when is_no_kr kr -> Some kr
            | _ -> None))
  in
  let e =
    match existing_kr with
    | None -> e
    | Some kr ->
        (* cleanup existing KR if needed *)
        if kr.title = "" || kr.objective = "" || kr.project = "" then
          remove t kr;
        KR.merge kr e
  in
  let update t =
    replace_no_case t.titles e.title e;
    match e.id with ID id -> replace_no_case t.ids id e | _ -> ()
  in
  let p =
    match find_no_case t.projects e.project with
    | Some p -> p
    | None ->
        let p = { name = e.project; objectives = Hashtbl.create 13 } in
        add_no_case t.projects e.project p;
        p
  in
  let o =
    match find_no_case p.objectives e.objective with
    | Some o -> o
    | None ->
        let o = { name = e.objective; krs = empty_krs () } in
        add_no_case p.objectives e.objective o;
        o
  in
  update t.all_krs;
  update o.krs

let empty () = { projects = Hashtbl.create 13; all_krs = empty_krs () }

let of_krs ?okr_db entries =
  let t = empty () in
  List.iter (add ?okr_db t) entries;
  t

let of_projects projects =
  let ids = ref [] in
  let titles = ref [] in
  List.iter
    (fun p ->
      iter_project
        (fun x ->
          titles := (x.title, x) :: !titles;
          match x.id with ID id -> ids := (id, x) :: !ids | _ -> ())
        p)
    projects;
  let ids = List.to_seq !ids |> Hashtbl.of_seq in
  let titles = List.to_seq !titles |> Hashtbl.of_seq in
  let projects =
    projects |> List.to_seq |> Seq.map (fun p -> (p.name, p)) |> Hashtbl.of_seq
  in
  { projects; all_krs = { ids; titles } }

let of_objectives ~project objectives =
  let objectives =
    objectives |> List.to_seq
    |> Seq.map (fun (o : objective) -> (o.name, o))
    |> Hashtbl.of_seq
  in
  let p : project = { name = project; objectives } in
  of_projects [ p ]

let of_markdown ?existing_report ?ignore_sections ?include_sections ?okr_db m =
  let new_krs, exns = Parser.of_markdown ?ignore_sections ?include_sections m in
  let old_krs = match existing_report with None -> [] | Some t -> all_krs t in
  let krs = old_krs @ new_krs in
  (of_krs ?okr_db krs, exns)

let make_objective ?show_time ?show_time_calc ?show_engineers o =
  let krs = Hashtbl.to_seq o.krs.ids |> Seq.map snd |> List.of_seq in
  let new_krs =
    Hashtbl.to_seq o.krs.titles
    |> Seq.map snd |> Seq.filter is_new_kr |> List.of_seq
  in
  let no_krs =
    Hashtbl.to_seq o.krs.titles
    |> Seq.map snd |> Seq.filter is_no_kr |> List.of_seq
  in
  let krs =
    List.sort KR.compare krs
    @ List.sort KR.compare new_krs
    @ List.sort KR.compare no_krs
  in
  match
    List.concat_map (KR.items ?show_time ?show_time_calc ?show_engineers) krs
  with
  | [] -> []
  | krs -> if o.name = "" then krs else Item.Title (2, o.name) :: krs

let make_project ?show_time ?show_time_calc ?show_engineers p =
  let os = List.of_seq (Hashtbl.to_seq p.objectives |> Seq.map snd) in
  let os = List.sort compare_objectives os in
  match
    List.concat_map
      (make_objective ?show_time ?show_time_calc ?show_engineers)
      os
  with
  | [] -> []
  | os -> if p.name = "" then os else Item.Title (1, p.name) :: os

let pp ?show_time ?show_time_calc ?show_engineers ppf t =
  let ps = List.of_seq (Hashtbl.to_seq t.projects |> Seq.map snd) in
  let ps = List.sort compare_projects ps in
  let doc =
    List.concat_map (make_project ?show_time ?show_time_calc ?show_engineers) ps
  in
  Printer.list ~sep:Printer.(newline ++ newline) Item.pp ppf doc;
  Printer.newline ppf ()

let print ?show_time ?show_time_calc ?show_engineers t =
  let pp = pp ?show_time ?show_time_calc ?show_engineers in
  Printer.to_stdout pp t
