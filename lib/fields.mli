type option

type kind =
  | Users
  | Pull_requests
  | Reviewers
  | Labels
  | Milestones
  | Repository
  | Title
  | Text
  | Single_select of option list
  | Number
  | Date
  | Iteration
  | Tracks
  | Tracked_by

type t

val empty : unit -> t
val option : id:string -> name:string -> option
val kind_of_string : string -> kind
val find : t -> Column.t -> kind * string
val add : t -> Column.t -> kind -> string -> unit
val pp : t Fmt.t
val pp_names : t Fmt.t
val get_id : name:string -> option list -> string
val to_json : t -> Yojson.Safe.t
val of_json : Yojson.Safe.t -> t
val same : string -> string -> bool
