open Bos_setup

val with_auth : token:string -> Curl.t -> Curl.t

module Pull_request : sig
  module Request : sig
    val node_id : user:string -> repo:string -> id:int -> Curl.t
    val ready_for_review : node_id:string -> Curl.t
  end

  module Response : sig
    val node_id : Yojson.Basic.t -> (string, R.msg) result
    val url : Yojson.Basic.t -> (string, R.msg) result
  end
end
