module Token : sig
  val t : string Lazy.t
end

val run : string -> Yojson.Safe.t Lwt.t
