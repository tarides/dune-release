open Bos_setup

type t = string

let drop_initial_v version =
  match String.head version with
  | Some ('v' | 'V') -> String.with_index_range ~first:1 version
  | None | Some _ -> version

let from_tag ~keep_v vcs t =
  let s = Vcs.unescape_tag vcs t in
  if keep_v then s else drop_initial_v s

let to_tag = Vcs.escape_tag
let of_string x = x
let pp = Fmt.string
let to_string x = x

module Changelog = struct
  type t = string
  type t' = string

  let of_string x = x
  let to_version ~keep_v x = if keep_v then x else drop_initial_v x
  let equal = String.equal
  let pp = Fmt.string
  let to_tag = Vcs.escape_tag
end
