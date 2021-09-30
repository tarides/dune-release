type t
(** [t] represents the high-level version of a project *)

val from_tag : keep_v:bool -> Vcs.t -> Vcs.Tag.t -> t
(** Constructs a [t] from a [Vcs.Tag.t], possibly dropping the leading v. *)

val to_tag : Vcs.t -> t -> Vcs.Tag.t
(** Converts a project version into a valid tag for VCS. *)

val of_string : string -> t
(** [of_string s] reads a value as-is as the project version. *)

val to_string : t -> string
(** [to_string v] converts the project version into a string. *)

val pp : t Fmt.t
(** Pretty print a [t]. *)

module Changelog : sig
  type t'

  type t
  (** [t] represents a project version read from the project changelog. *)

  val of_string : string -> t
  (** [of_string s] reads the changelog value from a string. *)

  val to_version : keep_v:bool -> t -> t'
  (** [to_version ~keep_v v] converts the changelog version into the actual
      project version. *)

  val equal : t -> t -> bool
  (** [equal a b] is [true] when [a] and [b] are equal. *)

  val pp : t Fmt.t
  (** Pretty print a [t]. *)

  val to_tag : Vcs.t -> t -> Vcs.Tag.t
  (** [to_tag vcs v] converts the change log version into a tag for VCS. *)
end
with type t' = t
