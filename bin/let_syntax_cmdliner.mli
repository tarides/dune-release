type 'a t := 'a Cmdliner.Term.t

val ( let+ ) : 'a t -> ('a -> 'b) -> 'b t
val ( and+ ) : 'a t -> 'b t -> ('a * 'b) t
