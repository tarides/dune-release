let warning =
  "dune-release delegates are deprecated. They will be removed in version \
   2.0.0."

let warning_usage : ('a, Format.formatter, unit, unit) format4 =
  "Warning: You are using delegates. The use of delegates is deprecated. It \
   will be removed in version 2.0.0."

let env_var_doc =
  "Warning: this environment variable is deprecated. It will be removed in \
   version 2.0.0. \n\
   The package delegate to use, see dune-release-delegate(7)."

let artefacts_warning =
  "Warning: publishing other artefacts is deprecated. It will be disabled in \
   version 2.0.0.\n"

let module_publish_man_alt =
  "Warning: this artefact is deprecated. It will be removed in version 2.0.0. \n\
  \ Publishes the alternative artefact of kind $(i,KIND) of a distribution \
   archive. The semantics of alternative artefacts is left to the delegate, it \
   could be anything, an email, a pointless tweet, a feed entry etc. See \
   dune-release-delegate(7) for more details."

let alt_artefacts_pp : ('a -> 'b, Format.formatter, unit) format =
  "alt-%s(deprecated)"

let publish_alt ?distrib_uri ~dry_run pkg kind =
  let open Bos_setup in
  App_log.unhappy (fun l ->
      l
        "Warning: the use of alternative artefacts is deprecated. It will be \
         removed in version 2.0.0.");
  App_log.status (fun l -> l "Publishing %s" kind);
  Pkg.distrib_file ~dry_run pkg >>= fun archive ->
  Pkg.publish_msg pkg >>= fun msg ->
  Delegate.publish_alt ?distrib_uri ~dry_run pkg ~kind ~msg ~archive
