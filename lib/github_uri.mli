module Repo_scheme : sig
  type t = HTTPS | GIT_HTTPS | GIT_SSH | GIT
end

module WWW_scheme : sig
  type t = HTTP | HTTPS
end

module type WWW = sig
  type t = {
    user : string;
    repo : string;
    scheme : WWW_scheme.t;
    path : Fpath.t option;
  }

  val make :
    ?path:Fpath.t -> user:string -> repo:string -> scheme:WWW_scheme.t -> t

  val of_string : string -> (t, Bos_setup.R.msg) result

  val to_string : t -> string

  val pp : Format.formatter -> t -> unit
end

module Homepage : WWW

module Doc : WWW

module Distrib : WWW

module Repo : sig
  type t = {
    user : string;
    repo : string;
    scheme : Repo_scheme.t;
    git_ext : bool;
  }

  val make :
    user:string -> repo:string -> scheme:Repo_scheme.t -> git_ext:bool -> t

  val of_string : string -> (t, Bos_setup.R.msg) result

  val to_string : t -> string

  val pp : Format.formatter -> t -> unit
end
