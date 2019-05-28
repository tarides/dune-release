open Bos_setup

type t = [ `Std_files |`Opam ]
(** The type for lints. *)

val all : t list
(** [all] is a list with all lint values. *)

val lint_pkg : dry_run:bool -> dir:Fpath.t -> Pkg.t -> t list -> (int, R.msg) result
(** [lint_pkg ~dry_run ~dir pkg lints] performs the lint checks in [lints] on [pkg]
    located in [dir]. *)
