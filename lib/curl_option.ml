open Astring

type auth = { user : string; token : string }

type t =
  | Location
  | User of auth
  | Silent
  | Show_error
  | Config of [ `Stdin | `File of string ]
  | Dump_header of [ `Ignore | `File of string ]
  | Data of [ `Data of string | `File of string ]
  | Data_binary of [ `Data of string | `File of string ]
  | Header of string

let to_string_list opts =
  List.fold_left
    (fun acc -> function Location -> "--location" :: acc
      | User { user; token } -> "--user" :: strf "%s:%s" user token :: acc
      | Silent -> "--silent" :: acc | Show_error -> "--show-error" :: acc
      | Config `Stdin -> "--config" :: "-" :: acc
      | Config (`File f) -> "--config" :: f :: acc
      | Dump_header `Ignore -> "--dump-header" :: "-" :: acc
      | Dump_header (`File f) -> "--dump-header" :: f :: acc
      | Data (`Data d) -> "--data" :: d :: acc
      (* Filenames should start with the letter [@]. *)
      | Data (`File f) -> "--data" :: strf "@@%s" f :: acc
      | Data_binary (`Data d) -> "--data-binary" :: d :: acc
      (* Filenames should start with the letter [@]. *)
      | Data_binary (`File f) -> "--data-binary" :: strf "@@%s" f :: acc
      | Header h -> "--header" :: h :: acc)
    [] (List.rev opts)
