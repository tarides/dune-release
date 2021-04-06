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
