open Bos_setup

let get_domain uri =
  match Text.split_uri uri with
  | None -> []
  | Some (_, host, _) -> List.rev (String.cuts ~sep:"." host)

let get_sld uri =
  match get_domain uri with _ :: sld :: _ -> Some sld | _ -> None

let append_to_base ~rel_path base =
  match String.head ~rev:true base with
  | None -> rel_path
  | Some '/' -> strf "%s%s" base rel_path
  | Some _ -> strf "%s/%s" base rel_path

let chop_ext u =
  match String.cut ~rev:true ~sep:"." u with None -> u | Some (u, _) -> u

let chop_git_prefix uri =
  match String.cut ~sep:"git+" uri with Some ("", rest) -> rest | _ -> uri

let to_https uri =
  match String.cut ~sep:"git@github.com:" uri with
  | Some ("", path) -> "https://github.com/" ^ chop_ext path
  | _ -> (
      match String.cut ~sep:"git+ssh://git@github.com/" uri with
      | Some ("", path) -> "https://github.com/" ^ chop_ext path
      | _ -> chop_git_prefix (chop_ext uri))

