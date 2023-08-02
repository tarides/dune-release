module Token : sig
  val set : string -> unit
  val t : string Lazy.t
end

val run : string -> Yojson.Safe.t Lwt.t
