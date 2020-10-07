(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

(** The entrypoint for the [distro] command. *)

val distrib :
  ?build_dir:Fpath.t ->
  dry_run:bool ->
  name:string option ->
  pkg_names:string list ->
  version:string option ->
  tag:string option ->
  keep_v:bool ->
  keep_dir:bool ->
  skip_lint:bool ->
  skip_build:bool ->
  skip_tests:bool ->
  include_submodules:bool ->
  unit ->
  (int, Bos_setup.R.msg) result
(** [distrib ~build_dir ~dry_run ~name ~pkg_names ~version ~tag ~keep_v
    ~keep_dir ~skip_lint ~skip_build ~skip_tests ()] creates a distribution
    archive for the package built with [name], [version] and [tag], in
    [build_dir]. Returns the exit code (0 for success, 1 for failure) or error
    messages.

    - [keep_v] indicates whether the version is prefixed by 'v'
    - If [keep_dir] is [true] the repository checkout used to create the
      distribution archive is kept in the build directory.
    - Unless [skip_lint] is set, lint checks are performed on the generated
      archive.
    - Unless [skip_build] is set the archive is built.
    - Unless [skip_tests] is set the tests of the package are executed from the
      archive. *)

(** The [distrib] command. *)

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
