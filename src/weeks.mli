type t

val all : t
val q1 : t
val q2 : t
val q3 : t
val q4 : t
val week : int -> t
val range : int -> int -> t
val union : t list -> t
val pp : t Fmt.t
val of_string : string -> (t, [ `Msg of string ]) result
val to_ints : t -> int list
