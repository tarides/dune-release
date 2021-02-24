val get_sld : string -> string option
(** Get the URI's second level domain, if it has one. *)

val append_to_base : rel_path:string -> string -> string
(** Append a relative path to a base URI. *)

val chop_git_prefix : string -> string
(** Chop the prefix [git+] from a URI, if any. *)

val to_https : string -> string
(** Convert [git@] and [git+ssh://] into https URI's. Leave other URI's as is. *)

module Github : sig
  val to_github_standard : string -> (string, [> Bos_setup.R.msg ]) result
  (** Convert a github pages URI into its correspondent repo URI. Leave other
      URI's as is. *)

  val get_user_and_repo :
    string -> (string * string, [> Bos_setup.R.msg ]) result
  (** Retrieve user name and repository name from a standard github URI. *)

  val split_doc_uri :
    string -> (string * string * Fpath.t, [> Bos_setup.R.msg ]) result
  (** Parse a github pages URI of the form $SCHEME://$USER.github.io/$REPO/$PATH
      into (user, repo, dir), where user=$USER and repo and dir are deduced from
      $PATH *)
end
