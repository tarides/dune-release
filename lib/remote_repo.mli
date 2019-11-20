type t

val make: string -> t
(** [make s] builds a remote repository type, such that: [uri (make s) = s]. *)

val uri: t -> string
(** [uri t] returns the uri used to build the remote repository type. *)

val user: t -> string option
(** [user t] is the username in the github URI [remote_uri], ie:

    - [user "git@github.com:username/repo.git"] is [Some "username"].
    - [user "https://github.com/username/repo.git"] is [Some "username"].
    - Returns [None] if [remote_uri] isn't in the expected format.
*)
