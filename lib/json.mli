open Bos_setup

val from_string : string -> (Yojson.Basic.t, R.msg) result
(** [from_string s] parses [s] and builds a Yojson.Basic.t type accordingly, or
    returns the associated error message if the input is not a valid JSON value. *)

val string_field : field:string -> Yojson.Basic.t -> (string, R.msg) result
(** [string_field ~field j] returns the value of field [field] from the JSON
    value [j] if it is a string, or returns the associated error message
    otherwise. *)

val int_field : field:string -> Yojson.Basic.t -> (int, R.msg) result
(** [int_field ~field j] returns the value of field [field] from the JSON value
    [j] if it is an integer, or returns the associated error message otherwise. *)
