module Delegates = struct
  let new_workflow =
    "You should write scripts invoking dune-release instead. Note that if you \
     require some values that used to be passed by dune-release to your \
     delegate you can obtain them with the `dune-release delegate-info` \
     command added in 1.4.0."

  let warning =
    "dune-release delegates are deprecated. They will be removed in version \
     2.0.0. "

  let artefacts_warning =
    "$(b,Warning:) publishing alternative artefacts is deprecated. It will be \
     disabled in version 2.0.0.\n"

  let env_var_warning =
    "$(b,Warning:) this environment variable is deprecated. It will be removed \
     in version 2.0.0."

  let warning_usage : ('a -> 'b, Format.formatter, unit, unit) format4 =
    "Warning: You are using delegates. The use of delegates is deprecated. It \
     will be removed in version 2.0.0. %s"

  let warning_usage_alt_artefacts :
      ('a -> 'b, Format.formatter, unit, unit) format4 =
    "Warning: You are using alternative artefacts. The use of alternative \
     artefacts is deprecated. It will be removed in version 2.0.0. %s"
end

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
