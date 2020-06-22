open Bos_setup

val error_message : Yojson.Basic.t -> string option
(** [error_message j] extracts the message from [j] if the JSON value [j]
    carries an error message. *)

module Upload_response : sig
  val browser_download_url : Yojson.Basic.t -> (string, R.msg) result
  (** [browser_download_url response] extracts the browser_download_url field
      from a github release asset upload response, or error messages. *)
end

module Release_response : sig
  val release_id : Yojson.Basic.t -> (int, R.msg) result
  (** [release_id response] extracts the id field from a github response, or
      error messages. *)
end

module Pull_request_response : sig
  val html_url :
    Yojson.Basic.t -> ([ `Already_exists | `Url of string ], R.msg) result
  (** [html_url response] extracts the html_url field from a github json
      response, or [`Already_exists] if the corresponding pull request already
      exists, or error messages. *)
end
