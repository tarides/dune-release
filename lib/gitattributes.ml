open Bos_setup

type pattern =
  | Exact of string  (** Exact match against basename or full path. *)
  | Prefix of string
      (** Pattern like [dir/**] that matches everything under a directory, but
          not the directory itself. *)
  | Glob of Re.re  (** Compiled glob pattern. *)

(** [glob_to_re pattern] is a compiled regex for glob [pattern]. Supports [*]
    (any chars except /), [?] (single char except /), and [**] (any path
    segments, but only when adjacent to /). *)
let glob_to_re pattern =
  let buf = Buffer.create (String.length pattern * 2) in
  Buffer.add_char buf '^';
  let len = String.length pattern in
  let rec loop i =
    if i >= len then ()
    else
      let c = pattern.[i] in
      match c with
      | '*' ->
          if i + 1 < len && pattern.[i + 1] = '*' then
            (* ** only crosses path separators when adjacent to / *)
            let preceded_by_slash = i > 0 && pattern.[i - 1] = '/' in
            let at_start = i = 0 in
            if i + 2 < len && pattern.[i + 2] = '/' then (
              (* **/ matches zero or more directories *)
              Buffer.add_string buf "(.*/)?";
              loop (i + 3))
            else if i + 2 >= len && (preceded_by_slash || at_start) then (
              (* /** at end or just ** alone - matches anything *)
              Buffer.add_string buf ".*";
              loop (i + 2))
            else (
              (* ** not adjacent to / - acts like * *)
              Buffer.add_string buf "[^/]*";
              loop (i + 2))
          else (
            (* * matches anything except path separator *)
            Buffer.add_string buf "[^/]*";
            loop (i + 1))
      | '?' ->
          (* ? matches any single character except path separator *)
          Buffer.add_string buf "[^/]";
          loop (i + 1)
      | '.' | '+' | '^' | '$' | '(' | ')' | '[' | ']' | '{' | '}' | '|' | '\\'
        ->
          (* Escape regex metacharacters *)
          Buffer.add_char buf '\\';
          Buffer.add_char buf c;
          loop (i + 1)
      | _ ->
          (* Literal character *)
          Buffer.add_char buf c;
          loop (i + 1)
  in
  loop 0;
  Buffer.add_char buf '$';
  Re.Pcre.regexp (Buffer.contents buf)

let parse_pattern s =
  let s = String.trim s in
  (* Remove leading slash if present - we always match relative paths *)
  let s =
    if String.is_prefix ~affix:"/" s then
      String.Sub.to_string (String.sub ~start:1 s)
    else s
  in
  let has_wildcard s = String.exists (fun c -> c = '*' || c = '?') s in
  if String.is_suffix ~affix:"/**" s then
    (* Directory pattern: match everything under the directory *)
    let prefix =
      String.Sub.to_string (String.sub ~stop:(String.length s - 3) s)
    in
    if has_wildcard prefix then
      (* Prefix contains wildcards, treat whole pattern as glob *)
      Glob (glob_to_re s)
    else Prefix prefix
  else if has_wildcard s then
    (* Has wildcards - compile as glob *)
    Glob (glob_to_re s)
  else
    (* Exact match *)
    Exact s

let matches path pattern =
  let path = Fpath.normalize path in
  let path_str = Fpath.to_string path in
  let basename = Fpath.basename path in
  match pattern with
  | Exact s ->
      (* Match against basename or full relative path *)
      String.equal s basename || String.equal s path_str
  | Prefix prefix ->
      (* Match everything under the directory, but not the directory itself *)
      String.is_prefix ~affix:(prefix ^ "/") path_str
  | Glob re ->
      (* Match against full path or basename for patterns like *.log *)
      Re.execp re path_str || Re.execp re basename

let parse_export_ignore content =
  (* Strip UTF-8 BOM if present at start of file *)
  let content =
    if String.is_prefix ~affix:"\xef\xbb\xbf" content then
      String.Sub.to_string (String.sub ~start:3 content)
    else content
  in
  content |> String.cuts ~sep:"\n"
  |> List.filter_map (fun line ->
         let line = String.trim line in
         (* Skip empty lines and comments *)
         if String.length line = 0 || String.is_prefix ~affix:"#" line then None
         else
           (* Format: <pattern> <attr1> <attr2> ...
              Attributes can be separated by spaces or tabs *)
           let parts =
             String.fields ~empty:false
               ~is_sep:(fun c -> c = ' ' || c = '\t')
               line
           in
           match parts with
           | pattern :: attrs
             when List.exists (String.equal "export-ignore") attrs ->
               Some (parse_pattern pattern)
           | _ -> None)

let read_export_ignore dir =
  let file = Fpath.(dir / ".gitattributes") in
  OS.File.exists file >>= function
  | false -> Ok []
  | true -> OS.File.read file >>| parse_export_ignore
