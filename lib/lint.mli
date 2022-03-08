open Bos_setup

type t = [ `Std_files | `Opam ]
(** The type for lints. *)

val opam_lint_impl :
  dry_run:bool ->
  opam_file_version:string option ->
  opam_tool_version:OpamTypes.version ->
  Fpath.t ->
  int ref

val all : t list
(** [all] is a list with all lint values. *)

val lint_packages :
  dry_run:bool ->
  dir:Fpath.t ->
  todo:[ `Opam | `Std_files ] list ->
  Pkg.t ->
  string list ->
  (int, [ `Msg of string ]) result
(** [lint_packages ~dry_run ~dir ~todo pkg pkg_names] performs the lint checks
    in [todo] on [pkg] located in [dir] for all opam files whose name is in
    [pkg_names], or - if [pkg_names] is empty - for all packages in [dir]. *)
