type t

val pp : t Fmt.t
val number : t -> int
val id : t -> string
val title : t -> string
val list : org:string -> repo:string -> unit -> t list Lwt.t

val create :
  org:string -> repo:string -> title:string -> body:string -> unit -> t Lwt.t
