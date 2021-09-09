open Bos_setup

type t = string

let drop_initial_v version =
  match String.head version with
  | Some ('v' | 'V') -> String.with_index_range ~first:1 version
  | None | Some _ -> version

let from_tag ~keep_v t =
  let s = Vcs.Tag.to_string t in
  if keep_v then s else drop_initial_v s

let to_tag x =
  (* TODO: handle v *)
  Vcs.Tag.from_string x

let from_string x = x

let pp = Fmt.string

let to_string x = x
