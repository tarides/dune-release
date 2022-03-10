(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

(** The entrypoint for the [distro] command. *)

val publish :
  ?build_dir:Fpath.t ->
  ?opam:Fpath.t ->
  ?change_log:Fpath.t ->
  ?distrib_file:Fpath.t ->
  ?publish_msg:string ->
  ?token:string Dune_release.Config.Cli.t ->
  pkg_names:string list ->
  version:Dune_release.Version.t option ->
  tag:Dune_release.Vcs.Tag.t option ->
  keep_v:bool Dune_release.Config.Cli.t ->
  dry_run:bool ->
  publish_artefacts:[ `Distrib | `Doc ] list ->
  yes:bool ->
  draft:bool ->
  unit ->
  (int, Bos_setup.R.msg) result
(** [publish ~build_dir ~opam ~change_log ~distrib_uri ~distrib_file
    ~publish_msg ~name ~pkg_names ~version ~tag ~keep_v ~dry_run
    ~publish_artefacts ~yes ~draft ()]
    publishes the artefacts [publish_artefacts] of the package built with
    [name], [version] and [tag]. Returns the exit code (0 for success, 1 for
    failure) or error messages.

    - [keep_v] indicates whether the version is prefixed by 'v'. *)

(** The [publish] command. *)

val cmd : int Cmdliner.Cmd.t

(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli

   Permission to use, copy, modify, and/or distribute this software for any
   purpose with or without fee is hereby granted, provided that the above
   copyright notice and this permission notice appear in all copies.

   THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
   WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
   MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
   ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
   WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
   ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
   OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
  ---------------------------------------------------------------------------*)
