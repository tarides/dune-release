module Repo_scheme = struct
  type t = HTTPS | GIT_HTTPS | GIT_SSH | GIT

  let pp fs = function
    | GIT -> Fmt.pf fs "git@"
    | GIT_SSH -> Fmt.pf fs "git+ssh://git@"
    | GIT_HTTPS -> Fmt.pf fs "git+https://"
    | HTTPS -> Fmt.pf fs "https://"
end

module WWW_scheme = struct
  type t = HTTP | HTTPS

  let pp fs = function
    | HTTP -> Fmt.pf fs "http://"
    | HTTPS -> Fmt.pf fs "https://"
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

open Bos_setup

module WWW = struct
  type t = {
    user : string;
    repo : string;
    scheme : WWW_scheme.t;
    path : Fpath.t option;
  }

  let make ?path ~user ~repo ~scheme = { user; repo; scheme; path }

  let parse error uri scheme regexp =
    try
      let grp = Re.exec (Re.Emacs.compile_pat regexp) uri in
      let user = Re.Group.get grp 1 in
      let repo = Re.Group.get grp 2 in
      let path =
        match Fpath.of_string (Re.Group.get grp 3) with
        | exception _ -> None
        | Error _ -> None
        | Ok path -> Some path
      in
      Ok { user; repo; scheme; path }
    with Not_found -> error uri

  let pp fs { user; repo; scheme; path } =
    match path with
    | Some p ->
        Format.fprintf fs "%agithub.com/%s/%s/%a" WWW_scheme.pp scheme user repo
          Fpath.pp p
    | None ->
        Format.fprintf fs "%agithub.com/%s/%s" WWW_scheme.pp scheme user repo

  let to_string = Format.asprintf "%a" pp
end

module Homepage = struct
  include WWW

  let error uri = R.error_msgf "%s is an invalid github homepage URI" uri

  let of_string = function
    | s when Bos_setup.String.is_prefix s ~affix:"http://github" ->
        parse error s WWW_scheme.HTTP
          "http://github\\.com/\\([^/]+\\)/\\([^/]+\\)/?\\(.*\\)"
    | s when Bos_setup.String.is_prefix s ~affix:"https://github" ->
        parse error s WWW_scheme.HTTPS
          "https://github\\.com/\\([^/]+\\)/\\([^/]+\\)/?\\(.*\\)"
    | s when Bos_setup.String.is_prefix s ~affix:"http://" ->
        parse error s WWW_scheme.HTTP
          "http://\\([^\\.]+\\).github\\.io/\\([^/]+\\)/?\\(.*\\)"
    | s when Bos_setup.String.is_prefix s ~affix:"https://" ->
        parse error s WWW_scheme.HTTPS
          "https://\\([^\\.]+\\).github\\.io/\\([^/]+\\)/?\\(.*\\)"
    | s -> error s
end

module Repo = struct
  type t = {
    user : string;
    repo : string;
    scheme : Repo_scheme.t;
    git_ext : bool;
  }

  let make ~user ~repo ~scheme ~git_ext = { user; repo; scheme; git_ext }

  let error uri = R.error_msgf "%s is an invalid github repository URI" uri

  let parse uri scheme regexp =
    try
      let grp = Re.exec (Re.Emacs.compile_pat regexp) uri in
      let user = Re.Group.get grp 1 in
      let repo = Re.Group.get grp 2 in
      let git_ext =
        try not (String.is_empty (Re.Group.get grp 3)) with Not_found -> false
      in
      Ok { user; repo; scheme; git_ext }
    with Not_found -> error uri

  let of_string = function
    | s when Bos_setup.String.is_prefix s ~affix:"https://" ->
        parse s Repo_scheme.HTTPS
          "https://github\\.com/\\([^/]+\\)/\\([^\\.]+\\)\\(\\.git\\)?"
    | s when Bos_setup.String.is_prefix s ~affix:"git+https://" ->
        parse s Repo_scheme.GIT_HTTPS
          "git\\+https://github\\.com/\\([^/]+\\)/\\([^\\.]+\\)\\(\\.git\\)?"
    | s when Bos_setup.String.is_prefix s ~affix:"git+ssh://" ->
        parse s Repo_scheme.GIT_SSH
          "git\\+ssh://git@github\\.com/\\([^/]+\\)/\\([^\\.]+\\)\\(\\.git\\)?"
    | s when Bos_setup.String.is_prefix s ~affix:"git@" ->
        parse s Repo_scheme.GIT
          "git@github\\.com:\\([^/]+\\)/\\([^\\.]+\\)\\(\\.git\\)?"
    | s -> error s

  let pp fs { user; repo; scheme; git_ext } =
    let repo = if git_ext then repo ^ ".git" else repo in
    match scheme with
    | HTTPS | GIT_HTTPS ->
        Format.fprintf fs "%agithub.com/%s/%s" Repo_scheme.pp scheme user repo
    | GIT | GIT_SSH ->
        Format.fprintf fs "%agithub.com:%s/%s" Repo_scheme.pp scheme user repo

  let to_string = Format.asprintf "%a" pp
end

module Doc = struct
  include WWW

  let error uri = R.error_msgf "%s is an invalid github documentation URI" uri

  let of_string = function
    | s when Bos_setup.String.is_prefix s ~affix:"http://" ->
        parse error s WWW_scheme.HTTP
          "http://\\([^\\.]+\\).github\\.io/\\([^/]+\\)/?\\(.*\\)"
    | s when Bos_setup.String.is_prefix s ~affix:"https://" ->
        parse error s WWW_scheme.HTTPS
          "https://\\([^\\.]+\\).github\\.io/\\([^/]+\\)/?\\(.*\\)"
    | s -> error s
end

module Distrib = struct
  include WWW

  let error uri = R.error_msgf "%s is an invalid github distribution URI" uri

  let of_string = function
    | s when Bos_setup.String.is_prefix s ~affix:"http://" ->
        parse error s WWW_scheme.HTTP
          "http://github\\.com/\\([^/]+\\)/\\([^/]+\\)/?\\(.*\\)"
    | s when Bos_setup.String.is_prefix s ~affix:"https://" ->
        parse error s WWW_scheme.HTTPS
          "https://github\\.com/\\([^/]+\\)/\\([^/]+\\)/?\\(.*\\)"
    | s -> error s
end
