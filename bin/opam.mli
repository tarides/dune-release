(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

(** Entrypoints for the [distro] command. *)

val get_pkgs :
  ?build_dir:Fpath.t ->
  ?opam:Fpath.t ->
  ?distrib_file:Fpath.t ->
  ?readme:Fpath.t ->
  ?change_log:Fpath.t ->
  ?publish_msg:string ->
  ?pkg_descr:Fpath.t ->
  dry_run:bool ->
  keep_v:bool Dune_release.Config.Cli.t ->
  tag:Dune_release.Vcs.Tag.t option ->
  pkg_names:string list ->
  version:Dune_release.Version.t option ->
  unit ->
  (Dune_release.Pkg.t list, Bos_setup.R.msg) result
(** [get_pkgs ~build_dir ~opam ~distrib_uri ~distrib_file ~readme ~change_log
    ~publish_msg ~pkg_descr ~dry_run ~keep_v ~tag ~name ~pkg_names ~version ()]
    returns the list of packages built from the [distrib_file] or the associated
    error messages. *)

val descr : pkgs:Dune_release.Pkg.t list -> (int, Bos_setup.R.msg) result
(** [descr ~pkgs] prints the opam description of packages [pkgs]. Returns the
    exit code (0 for success, 1 for failure) or error messages. *)

val pkg :
  ?distrib_uri:string ->
  dry_run:bool ->
  pkgs:Dune_release.Pkg.t list ->
  unit ->
  (int, Bos_setup.R.msg) result
(** [pkg ~dry_run ~pkgs] creates the opam package descriptions for packages
    [pkgs] and upgrades them to opam 2.0 if necessary. Returns the exit code (0
    for success, 1 for failure) or error messages. *)

val submit :
  ?local_repo:Fpath.t Dune_release.Config.Cli.t ->
  ?remote_repo:string Dune_release.Config.Cli.t ->
  ?opam_repo:string * string ->
  ?user:string ->
  ?token:string Dune_release.Config.Cli.t ->
  dry_run:bool ->
  pkgs:Dune_release.Pkg.t list ->
  pkg_names:string list ->
  no_auto_open:bool Dune_release.Config.Cli.t ->
  yes:bool ->
  draft:bool ->
  unit ->
  (int, Bos_setup.R.msg) result
(** [submit ?distrib_uri ?local_repo ?remote_repo ?opam_repo ?user ~dry_run
    ~pkgs ~pkg_names ~no_auto_open ~yes ~draft ()]
    opens a pull request on the opam repository for the packages [pkgs]. Returns
    the exit code (0 for success, 1 for failure) or error messages. *)

val field :
  pkgs:Dune_release.Pkg.t list ->
  field_name:string option ->
  (int, Bos_setup.R.msg) result
(** [field ~pkgs ~field_name] prints the value of the field [field_name] in the
    opam file of packages [pkgs]. Returns the exit code (0 for success, 1 for
    failure) or error messages. *)

(** The [opam] command. *)

val cmd : int Cmdliner.Term.t * Cmdliner.Term.info

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
