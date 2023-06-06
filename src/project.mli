type t
type db := Okra.Masterdb.t

val pp : ?order_by:Column.t -> ?filter_out:Filter.t -> t Fmt.t
val to_csv : t -> string
val filter : ?filter_out:Filter.t -> t -> t
val get : ?db:db -> org_name:string -> project_number:int -> unit -> t Lwt.t
val get_all : ?db:db -> org_name:string -> int list -> t list Lwt.t
val sync : heatmap:Heatmap.t -> t -> unit Lwt.t
