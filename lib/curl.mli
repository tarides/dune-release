val create_release :
  version:string -> msg:string -> user:string -> repo:string -> string list

val upload_archive :
  archive:Fpath.t -> user:string -> repo:string -> release_id:int -> string list

val open_pr :
  title:string ->
  user:string ->
  branch:string ->
  body:string ->
  opam_repo:string * string ->
  string list
