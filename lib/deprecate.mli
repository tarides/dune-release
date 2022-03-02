module Opam_1_x : sig
  val file_format_warning : string
  (** Message warning users that they need to upgrade their opam files from the
      1.x to the 2.x format to be compatible with dune-release 2.0.0 *)

  val remove_me : _
  (** Dummy value used to flag part of the code we should remove when dropping
      support for opam 1.x *)
end

module Config_user : sig
  val option_doc : string
  (** Documentation bit indicating the --user option is deprecated because it is
      redundant with the --remote-repo option. *)

  val option_use : string
  (** Message warning users they used the deprecated --user option and that they
      should use --remote-repo only. *)

  val config_field_doc : string
  (** Documentation bit indicating the user configuration field is deprecated
      because it is redundant with the remote field. *)

  val config_field_use : string
  (** Message warning users they are setting the deprecated user field of their
      configuration. *)
end
