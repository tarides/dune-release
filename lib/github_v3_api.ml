open Bos_setup

let error_message json =
  match Json.string_field ~field:"message" json with
  | Ok s -> Some s
  | Error _ -> None

let handle_errors json ~try_ ~on_ok ~default_msg ~handled_errors =
  match try_ json with
  | Ok x -> Ok (on_ok x)
  | Error _ -> (
      match error_message json with
      | Some github_msg -> (
          let matches (affix, _) = String.is_prefix github_msg ~affix in
          match List.find_opt matches handled_errors with
          | Some (_, ret) -> Ok ret
          | None ->
              R.error_msgf "%s, unexpected Github API error: %S" default_msg
                github_msg )
      | None -> R.error_msg default_msg )

module Upload_response = struct
  let browser_download_url json =
    handle_errors json
      ~try_:(Json.string_field ~field:"browser_download_url")
      ~on_ok:(fun x -> x)
      ~default_msg:"Could not retrieve archive download URL from response"
      ~handled_errors:[]
end

module Release_response = struct
  let release_id json =
    handle_errors json
      ~try_:(Json.int_field ~field:"id")
      ~on_ok:(fun x -> x)
      ~default_msg:"Could not retrieve release ID from response"
      ~handled_errors:[]
end

module Pull_request_response = struct
  let html_url json =
    handle_errors json
      ~try_:(Json.string_field ~field:"html_url")
      ~on_ok:(fun x -> `Url x)
      ~default_msg:"Could not retrieve pull request URL from response"
      ~handled_errors:[ ("A pull request already exists", `Already_exists) ]
end
