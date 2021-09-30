open Bos_setup

val with_auth : token:string -> Curl.t -> Curl.t

module Release : sig
  module Request : sig
    val get : tag:Vcs.Tag.t -> user:string -> repo:string -> Curl.t

    val create :
      version:Version.t ->
      tag:Vcs.Tag.t ->
      msg:string ->
      user:string ->
      repo:string ->
      draft:bool ->
      Curl.t

    val undraft : owner:string -> repo:string -> release_id:int -> Curl.t
  end

  module Response : sig
    val browser_download_url :
      name:string -> Yojson.Basic.t -> (string, R.msg) result
    (** [browser_download_url ~release_id response] extracts the
        browser_download_url field from a github release asset upload response
        named [name], or error messages. *)

    val release_id : Yojson.Basic.t -> (int, R.msg) result
    (** [release_id response] extracts the id field from a github response, or
        error messages. *)
  end
end

module Archive : sig
  module Request : sig
    val upload :
      archive:Fpath.t -> user:string -> repo:string -> release_id:int -> Curl.t
  end

  module Response : sig
    val browser_download_url : Yojson.Basic.t -> (string, R.msg) result
    (** [browser_download_url response] extracts the browser_download_url field
        from a github release asset upload response, or error messages. *)

    val name : Yojson.Basic.t -> (string, R.msg) result
    (** [name response] extracts the github name for the asset, which might
        differ from the filename for the archive we uploaded. *)
  end
end

module Pull_request : sig
  module Request : sig
    val open_ :
      title:string ->
      fork_owner:string ->
      branch:string ->
      body:string ->
      opam_repo:string * string ->
      draft:bool ->
      Curl.t
  end

  module Response : sig
    val html_url :
      Yojson.Basic.t -> ([ `Already_exists | `Url of string ], R.msg) result
    (** [html_url response] extracts the html_url field from a github json
        response, or [`Already_exists] if the corresponding pull request already
        exists, or error messages. *)

    val number : Yojson.Basic.t -> (int, R.msg) result
    (** [number response] extracts the number field from a github json response,
        or error messages. *)
  end
end
