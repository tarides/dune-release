open Bos_setup

let from_string str =
  match Yojson.Basic.from_string str with
  | exception Yojson.Json_error msg -> R.error_msg msg
  | json -> Ok json

let string_field ~field json =
  match Yojson.Basic.Util.member field json with
  | exception _ ->
      R.error_msgf "Could not find %S from:@ %a" field Yojson.Basic.pp json
  | `Null ->
      R.error_msgf "Could not find %S from:@ %a" field Yojson.Basic.pp json
  | `String s -> R.ok s
  | _ -> R.error_msgf "Could not parse %S from:@ %a" field Yojson.Basic.pp json

let int_field ~field json =
  match Yojson.Basic.Util.member field json with
  | exception _ ->
      R.error_msgf "Could not find %S from:@ %a" field Yojson.Basic.pp json
  | `Null ->
      R.error_msgf "Could not find %S from:@ %a" field Yojson.Basic.pp json
  | `Int i -> R.ok i
  | _ -> R.error_msgf "Could not parse %S from:@ %a" field Yojson.Basic.pp json

let list_field ~field json =
  match Yojson.Basic.Util.member field json with
  | exception _ ->
      R.error_msgf "Could not find %S from:@ %a" field Yojson.Basic.pp json
  | `Null ->
      R.error_msgf "Could not find %S from:@ %a" field Yojson.Basic.pp json
  | `List l -> R.ok l
  | _ -> R.error_msgf "Could not parse %S from:@ %a" field Yojson.Basic.pp json
