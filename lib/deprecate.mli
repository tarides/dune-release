module Delegates : sig
  val new_workflow : string
  (** Describes the new workflow to embed dune-release into customized release
      scripts. *)

  val warning : string
  (** Informs that the concept of delegate is deprecated. *)

  val artefacts_warning : string
  (** Same as [warning], but for alternative artefacts instead of delegates. *)

  val env_var_warning : string
  (** Same as [warning], but for the environment variable DUNE_RELEASE_DELEGATE
      instead of delegates themselves. *)

  val warning_usage : (string -> unit, Format.formatter, unit, unit) format4
  (** Informs that the user is using delegates and that those a deprecated. *)

  val warning_usage_alt_artefacts :
    (string -> unit, Format.formatter, unit, unit) format4
  (** Same as [warning_usage], but for alternative artefacts instead of
      delegates. *)
end

module Opam_1_x : sig
  val client_warning : string
  (** Message warning users of the opam 1.x CLI tool that they need to upgade to
      2.x to be able to be compatible with dune-release 2.0.0. *)

  val file_format_warning : string
  (** Message warning users that they need to upgrade their opam files from the
      1.x to the 2.x format to be compatible with dune-release 2.0.0 *)

  val remove_me : _
  (** Dummy value used to flag part of the code we should remove when dropping
      support for opam 1.x *)
end
