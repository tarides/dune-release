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

let src = Logs.Src.create "okra.parser"

module Log = (val Logs.src_log src : Logs.LOG)
open Omd

exception No_time_found of string (* Record found without a time record *)
exception Invalid_time of string (* Time record found, but has errors *)
exception No_work_found of string (* No work items found under KR *)
exception Multiple_time_entries of string (* More than one time entry found *)
exception No_KR_ID_found of string (* Empty or no KR ID *)
exception No_project_found of string (* No project found *)
exception Invalid_markdown_in_work_items of string
(* Subset of markdown not supported in work items *)

exception Not_all_includes_accounted_for of string list
(* There should be a section for all include sections passed to the parser *)

(* Types for parsing the AST *)
type t =
  | KR_id of KR.id (* ID of KR *)
  | KR_title of string (* Title without ID, tech lead *)
  | Work of Item.t list (* Work items *)
  | Time of string

type markdown = (string * string) list Omd.block list

let okr_re = Str.regexp "\\(.+\\) (\\([a-zA-Z]+[0-9]+\\))$"
(* Header: This is a KR (KR12) *)

let obj_re = Str.regexp "\\(.+\\) (\\([a-zA-Z ]+\\))$"
(* Header: This is an objective (Tech lead name) *)

let is_time_block = function
  | [ Paragraph (_, Text (_, s)) ] -> String.get (String.trim s) 0 = '@'
  | _ -> false

let time_block_is_sane s =
  let regexp = Str.regexp "^@[a-zA-Z0-9-]+[ ]+([0-9.]+[ ]+day[s]?)$" in
  let pieces = String.split_on_char ',' (String.trim s) in
  List.for_all
    (fun s ->
      let s = String.trim s in
      Str.string_match regexp s 0)
    pieces

let is_suffix suffix s =
  String.length s >= String.length suffix
  &&
  let suffix = String.uppercase_ascii suffix in
  let s = String.uppercase_ascii s in
  String.equal suffix
    (String.sub s
       (String.length s - String.length suffix)
       (String.length suffix))

let parse_okr_title s =
  (* todo: could match on ??) too? *)
  if is_suffix "(new kr)" s || is_suffix "(new okr)" s then
    let i = String.rindex s '(' in
    let t = String.trim (String.sub s 0 i) in
    Some (t, KR.New_KR)
  else if
    String.lowercase_ascii s = "other"
    || String.lowercase_ascii s = "others"
    || String.lowercase_ascii s = "off-kr"
    || String.lowercase_ascii s = "off kr"
    || String.lowercase_ascii s = "misc"
  then Some (s, No_KR)
  else if is_suffix "(no kr)" s || is_suffix "(no okr)" s then
    let i = String.rindex s '(' in
    let t = String.trim (String.sub s 0 i) in
    Some (t, No_KR)
  else
    match Str.string_match okr_re s 0 with
    | false -> None
    | true ->
        let t = String.trim (Str.matched_group 1 s) in
        let id = String.trim (Str.matched_group 2 s) in
        Some (t, ID id)

let dump_id ppf = function
  | KR.No_KR -> Fmt.string ppf "No KR"
  | New_KR -> Fmt.string ppf "New KR"
  | ID i -> Fmt.string ppf i

let dump_elt ppf = function
  | KR_id s -> Fmt.pf ppf "KR id: %a" dump_id s
  | KR_title s -> Fmt.pf ppf "KR title: %s" s
  | Work w -> Fmt.pf ppf "W: %a" Fmt.Dump.(list Item.dump) w
  | Time _ -> Fmt.pf ppf "Time: <not shown>"

let dump ppf okr = Fmt.Dump.list dump_elt ppf okr
let err_no_project s = raise (No_project_found s)
let err_multiple_time_entries s = raise (Multiple_time_entries s)
let err_markdown s = raise (Invalid_markdown_in_work_items s)
let err_no_work s = raise (No_work_found s)
let err_no_id s = raise (No_KR_ID_found s)
let err_time s = raise (Invalid_time s)
let err_no_time s = raise (No_time_found s)
let err_missing_includes s = raise (Not_all_includes_accounted_for s)

let rec inline = function
  | Concat (_, xs) -> Item.Concat (List.map inline xs)
  | Text (_, s) -> Item.Text s
  | Emph (_, s) -> Item.Emph (inline s)
  | Strong (_, s) -> Item.Strong (inline s)
  | Code (_, s) -> Item.Code s
  | Hard_break _ -> Item.Hard_break
  | Soft_break _ -> Item.Soft_break
  | Link (_, { label; destination; title }) ->
      Item.Link { label = inline label; destination; title }
  | Html (_, s) -> Item.Html s
  | Image (_, { label; destination; title }) ->
      Item.Image { label = inline label; destination; title }

let list_type = function
  | Ordered (i, c) -> Item.Ordered (i, c)
  | Bullet c -> Item.Bullet c

let rec block = function
  | Paragraph (_, x) -> Item.Paragraph (inline x)
  | List (_, x, _, bls) -> Item.List (list_type x, List.map (List.map block) bls)
  | Blockquote (_, x) -> Item.Blockquote (List.map block x)
  | Code_block (_, x, y) -> Item.Code_block (x, y)
  | Html_block _ -> err_markdown "Html_bloc"
  | Definition_list _ -> err_markdown "Definition_list"
  | Thematic_break _ -> err_markdown "Thematic_break"
  | Heading _ -> err_markdown "Heading"
  | Table _ -> err_markdown "Table"

let inline_to_string = Printer.to_string Item.pp_inline
let item_to_string = Printer.to_string Item.pp

let kr ~project ~objective = function
  | [] -> None
  | l ->
      (* This function expects a list of entries for the same KR, typically
         corresponding to a set of weekly reports. Each list item will consist
         of a list of okr_t items, which provides time, work items etc for this
         entry.

         This function will aggregate all entries for the same KR in an
         okr_entry record for easier processing later. *)
      let title = ref "" in
      let id = ref None in
      let time_entries = ref [] in

      (* Assume each item in list has the same O/KR/Proj, so just parse the
         first one *)
      (* todo we could sanity check here by verifying that every entry has the
         same KR/O *)
      List.iter
        (function
          | KR_title s -> title := s
          | KR_id s -> id := Some s
          | Time t ->
              (* check that time block makes sense *)
              if not (time_block_is_sane t) then err_time t else ();
              (* split on @, then extract first word and any float after *)
              let t_split = Str.split (Str.regexp "@+") t in
              let entry =
                List.filter_map
                  (fun s ->
                    match
                      Str.string_match
                        (Str.regexp
                           "^\\([a-zA-Z0-9-]+\\)[ ]+(\\([0-9.]+\\) day[s]?)")
                        s 0
                    with
                    | false -> None
                    | true ->
                        let user = Str.matched_group 1 s in
                        (* todo: let this conversion raise an exception, would
                           be nice to exit more cleanly, but it should be
                           fatal *)
                        let days = Float.of_string (Str.matched_group 2 s) in
                        Some (user, days))
                  t_split
              in
              time_entries := [ entry ] :: !time_entries
          | _ -> ())
        l;

      let title = String.trim !title in

      let () =
        match l with
        | [] -> ()
        | KR_title _ :: Time _ :: _ -> ()
        | KR_title _ :: KR_id _ :: Time _ :: _ -> ()
        | _ -> err_no_time title
      in

      let work =
        match (List.filter_map (function Work e -> Some e | _ -> None)) l with
        | [] -> err_no_work title
        | l -> l
      in

      let id = try Option.get !id with Invalid_argument _ -> No_KR in

      let time_entries =
        match !time_entries with
        | [] -> err_time title
        | [ e ] -> e
        | _ -> err_multiple_time_entries title
      in

      let project = String.trim project in
      let objective = String.trim objective in

      (* Construct final entry *)
      let kr = KR.v ~project ~objective ~title ~id ~time_entries work in
      Some kr

let block_okr = function
  | Paragraph (_, x) -> (
      let okr_title = String.trim (inline_to_string (inline x)) in
      match parse_okr_title okr_title with
      | None -> [ KR_title okr_title ]
      | Some (title, id) -> [ KR_title title; KR_id id ])
  | List (_, _, _, bls) ->
      List.map
        (fun bl ->
          if is_time_block bl then
            (* todo verify that this is true *)
            let time_s =
              String.concat "" (List.map (fun b -> item_to_string (block b)) bl)
            in
            Time time_s
          else
            let work_items = List.map block bl in
            Work work_items)
        bls
  | _ -> []

let strip_obj_lead s =
  match Str.string_match obj_re (String.trim s) 0 with
  | false -> String.trim s
  | true -> String.trim (Str.matched_group 1 s)

type state = {
  mutable current_o : string;
  mutable current_proj : string;
  ignore_sections : string list;
  include_sections : string list;
}

let init ?(ignore_sections = []) ?(include_sections = []) () =
  { current_o = ""; current_proj = ""; ignore_sections; include_sections }

let ignore_section t =
  match t.ignore_sections with
  | [] -> false
  | l ->
      (* ignore if proj or obj is in ignore_sections *)
      List.mem (String.uppercase_ascii t.current_proj) l
      || List.mem (String.uppercase_ascii t.current_o) t.ignore_sections

let include_section t =
  match t.include_sections with
  | [] -> Some "all"
  | l -> (
      match
        ( List.find_opt String.(equal @@ uppercase_ascii t.current_proj) l,
          List.find_opt String.(equal @@ uppercase_ascii t.current_o) l )
      with
      | (Some _ as t), _ | None, (Some _ as t) -> t
      | _ -> None)

let process_block state acc = function
  | Heading (_, n, il) ->
      let title =
        match il with
        (* Display header with level, strip lead from objectives if present *)
        | Text (_, s) -> strip_obj_lead s
        | _ -> "None"
      in
      let () =
        match n with
        | 2 -> state.current_o <- title
        | 1 ->
            state.current_o <- "";
            state.current_proj <- title
        | _ -> (* TODO: do now discard intermediate subsections *) ()
      in
      acc
  | List (_, _, _, bls) ->
      List.fold_left
        (fun ((sections, krs, exns) as acc) xs ->
          let includes = include_section state in
          if ignore_section state || Option.is_none includes then acc
          else
            let block = List.concat (List.map block_okr xs) in
            Log.debug (fun l -> l "items: %a" dump block);
            match
              kr ~project:state.current_proj ~objective:state.current_o block
            with
            (* Safe to Option.get given if-then-else *)
            | None -> (Option.get includes :: sections, krs, exns)
            | Some x -> (Option.get includes :: sections, x :: krs, exns)
            | exception e -> (Option.get includes :: sections, krs, e :: exns))
        acc bls
  | _ ->
      (* FIXME: also keep floating text *)
      acc

let process t ast = List.fold_left (process_block t) ([], [], []) ast

let check_includes u_includes (includes : string list) =
  let missing =
    List.(
      fold_left
        (fun acc v -> if mem v includes then acc else v :: acc)
        [] u_includes)
  in
  if missing = [] then () else err_missing_includes missing

let of_markdown ?(ignore_sections = [ "OKR Updates" ]) ?(include_sections = [])
    ast =
  let u_ignore = List.map String.uppercase_ascii ignore_sections in
  let u_include = List.map String.uppercase_ascii include_sections in
  let state = init ~ignore_sections:u_ignore ~include_sections:u_include () in
  let includes, krs, exns = process state ast in
  check_includes u_include (List.sort_uniq String.compare includes);
  (List.rev krs, exns)
