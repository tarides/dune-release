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
