(** Helper functions to manipulate URIs as OCaml strings *)

val get_domain : string -> string list
(** Get the domain for the given URI, as a list.
    [get_domain "https://github.com/org"] is [["com"; "github"]]. *)

val get_sld : string -> string option
(** Get the URI's second level domain, if it has one. *)

val append_to_base : rel_path:string -> string -> string
(** Append a relative path to a base URI. *)

val chop_git_prefix : string -> string
(** Chop the prefix [git+] from a URI, if any. *)

val to_https : string -> string
(** Convert [git@] and [git+ssh://] into https URI's. Leave other URI's as is. *)
