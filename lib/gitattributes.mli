(** Gitattributes parsing for export-ignore.

    Parses [.gitattributes] files and extracts patterns marked with the
    [export-ignore] attribute. These patterns can be used to exclude files from
    distribution archives. *)

open Bos_setup

(** {1 Patterns} *)

type pattern
(** The type for gitattributes patterns. *)

val parse_pattern : string -> pattern
(** [parse_pattern s] is the pattern parsed from string [s]. Supports:
    - Exact matches: [filename]
    - Directory patterns: [dir/**]
    - Glob patterns: [*.ext], [prefix*] *)

val matches : Fpath.t -> pattern -> bool
(** [matches path pattern] holds if [path] matches [pattern]. [path] should be
    relative to the repository root. *)

(** {1 Parsing .gitattributes} *)

val parse_export_ignore : string -> pattern list
(** [parse_export_ignore content] is the list of patterns marked with
    [export-ignore] in [.gitattributes] file [content]. *)

val read_export_ignore : Fpath.t -> (pattern list, R.msg) result
(** [read_export_ignore dir] is the list of patterns marked with [export-ignore]
    in [dir/.gitattributes], or the empty list if the file doesn't exist. *)
