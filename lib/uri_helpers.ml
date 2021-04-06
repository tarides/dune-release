open Bos_setup

type uri = { scheme : string option; domain : string list; path : string list }

let pp_uri fmt { scheme; domain; path } =
  Format.fprintf fmt "@[<hov 2>{ scheme = %a;@ domain = %a;@ path = %a }@]"
    Stdext.(Option.pp String.pp)
    scheme
    Stdext.(List.pp String.pp)
    domain
    Stdext.(List.pp String.pp)
    path

let equal_uri uri uri' =
  let { scheme; domain; path } = uri in
  let { scheme = s; domain = d; path = p } = uri' in
  Stdext.Option.equal String.equal scheme s
  && Stdext.List.equal String.equal domain d
  && Stdext.List.equal String.equal path p

let parse_domain domain = List.rev (String.cuts ~sep:"." domain)

let parse uri =
  let scheme, remainder =
    match String.cut ~sep:"://" uri with
    | None -> (None, uri)
    | Some (scheme, remainder) -> (Some scheme, remainder)
  in
  let raw_domain, raw_path =
    (* We mark the separation between domain and path at the first
       occurence of [':'] or ['/'] to support git@github.com: format
       as well as regular URIs *)
    let separator_index =
      String.find (function ':' | '/' -> true | _ -> false) remainder
    in
    match separator_index with
    | None -> (remainder, "")
    | Some i ->
        let domain = String.with_index_range ~first:0 ~last:(i - 1) remainder in
        let path = String.with_range ~first:(i + 1) remainder in
        (domain, path)
  in
  match (raw_domain, raw_path) with
  | "", _ -> None
  | _, "" -> Some { scheme; domain = parse_domain raw_domain; path = [] }
  | _, _ ->
      Some
        {
          scheme;
          domain = parse_domain raw_domain;
          path = String.cuts ~sep:"/" raw_path;
        }

let get_sld uri =
  match parse uri with
  | Some { domain = _ :: sld :: _; _ } -> Some sld
  | _ -> None

let append_to_base ~rel_path base =
  match String.head ~rev:true base with
  | None -> rel_path
  | Some '/' -> strf "%s%s" base rel_path
  | Some _ -> strf "%s/%s" base rel_path

let chop_git_prefix uri =
  match String.cut ~sep:"git+" uri with Some ("", rest) -> rest | _ -> uri
