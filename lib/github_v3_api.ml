open Bos_setup

module Upload_response = struct
  let browser_download_url = Json.string_field ~field:"browser_download_url"
end

module Release_response = struct
  let release_id = Json.int_field ~field:"id"
end

let error_message json =
  match Yojson.Basic.Util.member "message" json with
  | `String s -> Some s
  | _ -> None

module Pull_request_response = struct
  let html_url json =
    match Yojson.Basic.Util.member "html_url" json with
    | `String s -> R.ok (`Url s)
    | `Null -> (
        match error_message json with
        | Some msg
          when String.is_prefix msg ~affix:"A pull request already exists" ->
            R.ok `Already_exists
        | Some msg ->
            R.error_msgf
              "Could not find field html_url, unexpected error %S in response:\n\
               %a"
              msg Yojson.Basic.pp json
        | None ->
            R.error_msgf
              "Could not find field html_url or error message in response:\n%a"
              Yojson.Basic.pp json )
    | _ ->
        R.error_msgf "Could not parse html_url in response:\n%a" Yojson.Basic.pp
          json
end
