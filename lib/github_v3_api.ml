open Bos_setup

module Upload_response = struct
  let browser_download_url json =
    match Json.string_field ~field:"browser_download_url" json with
    | Ok x -> Ok x
    | Error _ ->
        R.error_msgf "Could not retrieve archive download URL from response"
end

module Release_response = struct
  let release_id json =
    match Json.int_field ~field:"id" json with
    | Ok x -> Ok x
    | Error _ -> R.error_msgf "Could not retrieve release ID from response"
end

let error_message json =
  match Json.string_field ~field:"message" json with
  | Ok s -> Some s
  | Error _ -> None

module Pull_request_response = struct
  let html_url json =
    match Json.string_field ~field:"html_url" json with
    | Ok x -> Ok (`Url x)
    | Error _ -> (
        match error_message json with
        | Some msg
          when String.is_prefix msg ~affix:"A pull request already exists" ->
            R.ok `Already_exists
        | Some msg ->
            R.error_msgf
              "Could not retrieve pull request URL from response, unexpected \
               error: %S"
              msg
        | None ->
            R.error_msgf "Could not retrieve pull request URL from response" )
end
