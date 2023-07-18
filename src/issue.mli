type t

val v : ?title:string -> ?body:string -> ?url:string -> ?closed:bool -> int -> t
val pp : t Fmt.t
val number : t -> int
val body : t -> string
val id : t -> string
val title : t -> string
val url : t -> string
val list : org:string -> repo:string -> unit -> t list Lwt.t
val tracks : t -> string list
val with_tracks : t -> string list -> t
val update : t -> unit Lwt.t
val to_json : t -> Yojson.Safe.t
val of_json : Yojson.Safe.t -> t
val copy_tracks : src:t -> dst:t -> unit
val closed : t -> bool
val update_state : issue_id:string -> [ `Open | `Closed ] -> string

val create :
  org:string -> repo:string -> title:string -> body:string -> unit -> t Lwt.t
