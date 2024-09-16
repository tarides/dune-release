module Query : sig
  type t

  val is : string -> t
  val not : t -> t
  val starts_with : string -> t
  val make : string -> t
  val pp : t Fmt.t
end

type t = (Column.t * Query.t) list

val default_out : t
val eval : get:(Column.t -> string) -> t -> bool
