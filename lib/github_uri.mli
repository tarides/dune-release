type t = { owner : string; repo : string }

val equal : t -> t -> bool

val pp : Format.formatter -> t -> unit

val from_string : string -> t option
(** Parse a github URI into owner and repo. Return [None] if the given URI isn't
    a github one. *)

val from_gh_pages : string -> (t * Fpath.t) option
(** Parse a github pages URI of the form <owner>.github.io/<repo>/<extra_path>
    into [({owner; repo}, extra_path)]. [extra_path] is [Fpath.v "."] if there
    is no such component in the URI. Return [None] if the URI isn't a gh-pages
    one. *)

val to_https : t -> string
(** Returns the given github URI as HTTPS URI, in string form *)

val to_ssh : t -> string
(** Returns the given github URI as ["git@github"] SSH URI, in string form *)
