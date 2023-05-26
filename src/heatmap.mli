type t

val of_report : Report.t -> t
val start_date : t -> string -> (int * int) option
val end_date : t -> string -> (int * int) option
val pp : t Fmt.t
