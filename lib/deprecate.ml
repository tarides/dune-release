module Opam_1_x = struct
  let client_warning =
    "The opam client 1.x is deprecated and its support will be dropped in \
     dune-release 2.0.0, please switch to opam 2"

  let file_format_warning =
    "The opam file format 1.x is deprecated and its support will be dropped in \
     dune-release 2.0.0, please switch to opam 2"

  let remove_me : _ = Obj.magic ()
end

module Config_user = struct
  let option_doc =
    "This option is deprecated and will be removed in 2.0.0 as the user is \
     redundant with the remote opam-repository fork from your configuration's \
     $(b,remote) field or from the $(b,--remote-repo) option. Please use those \
     instead."

  let option_use =
    "The --user option is deprecated and will be removed in 2.0.0 as the user \
     is redundant with the remote opam-repository fork from your \
     configuration's `remote` field or from the --remote-repo option. Please \
     use those instead.\n\
     Note that the user you provided will be ignored in favor of the above \
     mentioned config field or command line option."

  let config_field_doc =
    "This configuration field is deprecated and will be removed in 2.0.0 as it \
     is redundant with the $(b,remote) field. Its value will be ignored."

  let config_field_use =
    "The user configuration field is deprecated and will be removed in 2.0.0 \
     as it is redundant with the remote field. Setting it to the wrong value \
     can lead to bugs. Please use the remote field only."
end
