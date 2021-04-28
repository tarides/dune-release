(** Helper functions to manipulate URIs as OCaml strings *)

type uri = { scheme : string option; domain : string list; path : string list }
(** Helper type describing the content of an URI to facilitate parsing. Scheme
    is None if no explicit scheme was specified. The domain is a non empty list
    in hierarchical order, e.g. [\["io"; "github"; "me"\]] for ["me.github.io"].
    The path is [\[\]] if there was no path and a list of the path components,
    e.g. [\["some"; "path"\]] for ["domain.com/some/path"]. *)

val pp_uri : Format.formatter -> uri -> unit

val equal_uri : uri -> uri -> bool

val parse : string -> uri option
(** Parses an URI as a string. Returns [None] if the URI can't be properly
    parsed. The domain and path are determined based on the first ['/'] or [':']
    separator to support either regular URIs or ["github.com:owner/..."] URIs. *)

val get_sld : string -> string option
(** Get the URI's second level domain, if it has one. *)

val append_to_base : rel_path:string -> string -> string
(** Append a relative path to a base URI. *)

val chop_git_prefix : string -> string
(** Chop the prefix [git+] from a URI, if any. *)
