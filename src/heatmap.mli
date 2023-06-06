type t

val of_report : Report.t -> t
val start_date : t -> string -> (int * int) option
val end_date : t -> string -> (int * int) option
val pp : t Fmt.t
val pp_start_date : (int * int) Fmt.t
val pp_end_date : (int * int) Fmt.t
