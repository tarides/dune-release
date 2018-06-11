(* From dune API. TODO: use the API directly once it's public. *)

(** Implement the XDG specification
    http://standards.freedesktop.org/basedir-spec/basedir-spec-latest.html
*)

(** The directory where the application should read/write config files. *)
val config_dir : string

(** The directory where the application should read/write data files. *)
val data_dir : string

(** The directory where the application should read/write cached files. *)
val cache_dir : string

val home: string
