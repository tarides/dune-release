type option
type kind = Text | Date | Single_select of option list
type t

val empty : unit -> t
val option : id:string -> name:string -> option
val kind_of_string : string -> kind
val string_of_kind : kind -> string
val find : t -> Column.t -> kind * string
val add : t -> Column.t -> kind -> string -> unit
val pp : t Fmt.t
val pp_names : t Fmt.t
val get_id : name:string -> option list -> string
val to_json : t -> Yojson.Safe.t
val of_json : Yojson.Safe.t -> t
val same : string -> string -> bool
