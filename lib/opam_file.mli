val upgrade :
  filename:string ->
  url:OpamFile.URL.t ->
  id:string ->
  version:[ `V1 of OpamFile.Descr.t | `V2 ] ->
  OpamFile.OPAM.t ->
  OpamFile.OPAM.t
(** [upgrade ~filename ~url ~id ~version opam_t] produces the content of the
    opam file for the opam package, from the old [opam_t] content, migrating to
    the most supported format if needed (depending on [version]), setting the
    'url' field with [url], setting the 'x-commit-hash' to [id], and stripping
    the 'version' and 'name' fields. *)
