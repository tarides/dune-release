type t
type db := Okra.Masterdb.t

val org : t -> string
val number : t -> int
val pp : ?order_by:Column.t -> ?filter_out:Filter.t -> t Fmt.t
val to_csv : t -> string
val filter : ?filter_out:Filter.t -> t -> t
val sync : ?heatmap:Heatmap.t -> ?db:db -> t -> unit Lwt.t
val lint : ?heatmap:Heatmap.t -> db:db -> t -> unit
val cards : t -> Card.t list
val id : t -> string
val fields : t -> Fields.t

(** Local dumps *)

val to_json : t -> Yojson.Safe.t
val of_json : Yojson.Safe.t -> t

(** Queries *)

val get : org:string -> project_number:int -> unit -> t Lwt.t
val get_all : org:string -> int list -> t list Lwt.t

val get_id_and_fields :
  org:string -> project_number:int -> (string * Fields.t) Lwt.t
