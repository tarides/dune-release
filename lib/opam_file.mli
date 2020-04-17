val upgrade :
  url:OpamFile.URL.t ->
  version:[ `V1 of OpamFile.Descr.t | `V2 ] ->
  OpamFile.OPAM.t ->
  OpamFile.OPAM.t
(** [upgrade ~url ~version opam_t] produces the content of the opam file for the
    opam package, from the old [opam_t] content, migrating to the most supported
    format if needed (depending on [version]), setting the 'url' field with
    [url] and stripping the 'version' and 'name' fields. *)
