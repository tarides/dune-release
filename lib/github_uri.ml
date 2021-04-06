open Bos_setup

type t = { owner : string; repo : string }

let equal t t' =
  let { owner; repo } = t in
  let { owner = owner'; repo = repo' } = t' in
  String.equal owner owner' && String.equal repo repo'

let pp fmt { owner; repo } =
  Format.fprintf fmt "@[<hov 2>{ owner = %S;@ repo = %S }@]" owner repo

let drop_git_ext repo =
  let affix = ".git" in
  if String.is_suffix ~affix repo then
    let len = String.length repo - String.length affix in
    StringLabels.sub ~pos:0 ~len repo
  else repo

let from_string uri =
  let uri = Uri_helpers.parse uri in
  match uri with
  | Some
      {
        scheme = Some ("git+https" | "https") | None;
        domain = [ "com"; "github" ];
        path = [ owner; repo ];
      }
  | Some
      {
        scheme = Some "https" | None;
        domain = [ "io"; "github"; owner ];
        path = repo :: _;
      }
  | Some
      {
        scheme = Some ("git+ssh" | "ssh") | None;
        domain = [ "com"; "git@github" ];
        path = [ owner; repo ];
      } ->
      let repo = drop_git_ext repo in
      Some { owner; repo }
  | _ -> None

let fpath_of_list l =
  let rec aux acc l =
    match l with [] | [ "" ] -> acc | hd :: tl -> aux Fpath.(acc / hd) tl
  in
  match l with [] | [ "" ] -> Fpath.v "." | hd :: tl -> aux (Fpath.v hd) tl

let from_gh_pages uri =
  let uri = Uri_helpers.parse uri in
  match uri with
  | Some
      {
        scheme = Some "https" | None;
        domain = [ "io"; "github"; owner ];
        path = repo :: rest;
      } ->
      Some ({ owner; repo }, fpath_of_list rest)
  | _ -> None

let to_https { owner; repo } =
  Printf.sprintf "https://github.com/%s/%s" owner repo

let to_ssh { owner; repo } =
  Printf.sprintf "git@github.com:%s/%s.git" owner repo
