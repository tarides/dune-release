type t

val from_tag : keep_v:bool -> Vcs.Tag.t -> t

val to_tag : t -> Vcs.Tag.t

val from_string : string -> t

val to_string : t -> string

val pp : t Fmt.t
