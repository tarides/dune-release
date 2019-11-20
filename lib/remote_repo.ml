type t = { uri: string; user: string option }

let user_from_regexp_opt uri regexp =
  try Some (Re.(Group.get (exec (Emacs.compile_pat regexp) uri) 1))
  with Not_found -> None

let make uri =
  let user =
    match uri with
    | _ when Bos_setup.String.is_prefix uri ~affix:"git@" ->
        user_from_regexp_opt uri "git@github\\.com:\\(.+\\)/.+\\(\\.git\\)?"
    | _ when Bos_setup.String.is_prefix uri ~affix:"https://" ->
        user_from_regexp_opt uri "https://github\\.com/\\(.+\\)/.+\\(\\.git\\)?"
    | _ -> None
  in
  { uri; user }

let uri t = t.uri

let user t = t.user
