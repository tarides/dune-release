type t = { url : string; args : Curl_option.t list }

val create_release :
  version:string -> msg:string -> user:string -> repo:string -> t

val upload_archive :
  archive:Fpath.t -> user:string -> repo:string -> release_id:int -> t

val open_pr :
  title:string ->
  user:string ->
  branch:string ->
  body:string ->
  opam_repo:string * string ->
  t

val with_auth : auth:Curl_option.auth -> t -> t
