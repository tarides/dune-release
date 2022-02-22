open Dune_release

(** expose the [check function]. *)
val check : [< `Package_names of string list ] ->
    [< `Package_version of Version.t option ] ->
    [< `Dist_tag of Vcs.Tag.t option ] ->
    [< `Keep_v of bool Dune_release.Config.Cli.t ] ->
    [< `Build_dir of Fpath.t option ] ->
    [< `Skip_lint of bool ] ->
    [< `Skip_build of bool ] ->
    [< `Skip_tests of bool ] -> [< `Working_tree of bool ] -> int

(** The [check] command. *)

val cmd : int Cmdliner.Cmd.t
