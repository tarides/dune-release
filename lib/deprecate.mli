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
