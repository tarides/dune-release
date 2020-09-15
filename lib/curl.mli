type t = { url : string; meth : Curly.Meth.t; args : Curl_option.t list }

val create_release :
  version:string ->
  tag:string ->
  msg:string ->
  user:string ->
  repo:string ->
  draft:bool ->
  t

val get_release : version:string -> user:string -> repo:string -> t

val undraft_release : user:string -> repo:string -> release_id:int -> t

val upload_archive :
  archive:Fpath.t -> user:string -> repo:string -> release_id:int -> t

val open_pr :
  title:string ->
  user:string ->
  branch:Vcs.commit_ish ->
  body:string ->
  opam_repo:string * string ->
  draft:bool ->
  t

val with_auth : auth:Curl_option.auth -> t -> t
