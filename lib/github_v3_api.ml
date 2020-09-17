open Bos_setup

let is_handled errors (affix, _) =
  List.exists
    (fun error ->
      match Json.string_field ~field:"message" error with
      | Ok x -> String.is_prefix ~affix x
      | Error _ -> false)
    errors

let pp_break_then_string ?(pre = "") ?(post = "") fs = function
  | Ok x -> Fmt.fmt "@;%s%S%s" fs pre x post
  | Error _ -> Fmt.nop fs ()

let pp_errors fs errors =
  List.iter
    (fun error ->
      let message = Json.string_field ~field:"message" error in
      let code = Json.string_field ~field:"code" error in
      pp_break_then_string ~pre:"- Error message: " fs message;
      pp_break_then_string ~pre:"- Code: " fs code)
    errors

let handle_errors json ~try_ ~on_ok ~default_msg ~handled_errors =
  match try_ json with
  | Ok x -> Ok (on_ok x)
  | Error _ -> (
      let errors =
        match Json.list_field ~field:"errors" json with
        | Ok errors -> errors
        | Error _ -> []
      in
      match List.find_opt (is_handled errors) handled_errors with
      | Some (_, ret) -> Ok ret
      | None ->
          Json.string_field ~field:"message" json >>= fun message ->
          let documentation_url =
            Json.string_field ~field:"documentation_url" json
          in
          R.error_msgf
            "@[<v 2>Github API error:@ %s@;Github API returned: %S%a%a@]"
            default_msg message
            (pp_break_then_string ~pre:"See the documentation "
               ~post:" that might help you resolve this error.")
            documentation_url pp_errors errors )

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
