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
  | Error err -> (
      let errors =
        match Json.list_field ~field:"errors" json with
        | Ok errors -> errors
        | Error _ -> []
      in
      match List.find_opt (is_handled errors) handled_errors with
      | Some (_, ret) -> Ok ret
      | None -> (
          match Json.string_field ~field:"message" json with
          | Ok message ->
              let documentation_url =
                Json.string_field ~field:"documentation_url" json
              in
              R.error_msgf
                "@[<v 2>Github API error:@ %s@;Github API returned: %S%a%a@]"
                default_msg message
                (pp_break_then_string ~pre:"See the documentation "
                   ~post:" that might help you resolve this error.")
                documentation_url pp_errors errors
          | Error _ -> Error err))

let with_auth ~auth Curl.{ url; meth; args } =
  Curl.{ url; meth; args = Curl_option.User auth :: args }

module Release = struct
  module Request = struct
    let get ~version ~user ~repo =
      let url =
        strf "https://api.github.com/repos/%s/%s/releases/tags/%s" user repo
          version
      in
      let args =
        let open Curl_option in
        [ Location; Silent; Show_error; Config `Stdin; Dump_header `Ignore ]
      in
      { url; meth = `GET; args }

    let create ~version ~tag ~msg ~user ~repo ~draft =
      let json =
        Yojson.Basic.to_string
          (`Assoc
            [
              ("tag_name", `String tag);
              ("name", `String version);
              ("body", `String msg);
              ("draft", `Bool draft);
            ])
      in
      let url = strf "https://api.github.com/repos/%s/%s/releases" user repo in
      let args =
        let open Curl_option in
        [
          Location;
          Silent;
          Show_error;
          Config `Stdin;
          Dump_header `Ignore;
          Data (`Data json);
        ]
      in
      Curl.{ url; meth = `POST; args }

    let undraft ~user ~repo ~release_id =
      let json = Yojson.Basic.to_string (`Assoc [ ("draft", `Bool false) ]) in
      let url =
        strf "https://api.github.com/repos/%s/%s/releases/%i" user repo
          release_id
      in
      let args =
        let open Curl_option in
        [
          Location;
          Silent;
          Show_error;
          Config `Stdin;
          Dump_header `Ignore;
          Data (`Data json);
        ]
      in
      Curl.{ url; meth = `PATCH; args }
  end

  module Response = struct
    let same_name name json =
      match Json.string_field ~field:"name" json with
      | Ok name' -> String.equal name name'
      | Error _ -> false

    let browser_download_url ~name json =
      let name = Fpath.to_string name in
      handle_errors json
        ~try_:(fun json ->
          Json.list_field ~field:"assets" json >>= fun assets ->
          match List.find_opt (same_name name) assets with
          | Some json -> Json.string_field ~field:"browser_download_url" json
          | None -> R.error_msg "No asset matches the release")
        ~on_ok:(fun x -> x)
        ~default_msg:
          (Format.sprintf
             "Could not retrieve archive download URL for asset %s from \
              response"
             name)
        ~handled_errors:[]

    let release_id json =
      handle_errors json
        ~try_:(Json.int_field ~field:"id")
        ~on_ok:(fun x -> x)
        ~default_msg:"Could not retrieve release ID from response"
        ~handled_errors:[]
  end
end

module Archive = struct
  module Request = struct
    let upload ~archive ~user ~repo ~release_id =
      let url =
        strf "https://uploads.github.com/repos/%s/%s/releases/%d/assets?name=%s"
          user repo release_id (Fpath.filename archive)
      in
      let args =
        let open Curl_option in
        [
          Location;
          Silent;
          Show_error;
          Config `Stdin;
          Dump_header `Ignore;
          Header "Content-Type:application/x-tar";
          Data_binary (`File (Fpath.to_string archive));
        ]
      in
      Curl.{ url; meth = `POST; args }
  end

  module Response = struct
    let browser_download_url json =
      handle_errors json
        ~try_:(Json.string_field ~field:"browser_download_url")
        ~on_ok:(fun x -> x)
        ~default_msg:"Could not retrieve archive download URL from response"
        ~handled_errors:[]
  end
end

module Pull_request = struct
  module Request = struct
    let open_ ~title ~user ~branch ~body ~opam_repo ~draft =
      let base, repo = opam_repo in
      let url = strf "https://api.github.com/repos/%s/%s/pulls" base repo in
      let json =
        Yojson.Basic.to_string
          (`Assoc
            [
              ("title", `String title);
              ("base", `String "master");
              ("body", `String body);
              ("head", `String (strf "%s:%s" user branch));
              ("draft", `Bool draft);
            ])
      in
      let args =
        let open Curl_option in
        [
          Silent;
          Show_error;
          Config `Stdin;
          Dump_header `Ignore;
          Data (`Data json);
        ]
      in
      Curl.{ url; meth = `POST; args }

    let undraft ~opam_repo ~pr_id =
      let base, repo = opam_repo in
      let url =
        strf "https://api.github.com/repos/%s/%s/pulls/%i" base repo pr_id
      in
      let json = Yojson.Basic.to_string (`Assoc [ ("draft", `Bool false) ]) in
      let args =
        let open Curl_option in
        [
          Silent;
          Show_error;
          Config `Stdin;
          Dump_header `Ignore;
          Data (`Data json);
        ]
      in
      Curl.{ url; meth = `PATCH; args }
  end

  module Response = struct
    let html_url json =
      handle_errors json
        ~try_:(Json.string_field ~field:"html_url")
        ~on_ok:(fun x -> `Url x)
        ~default_msg:"Could not retrieve pull request URL from response"
        ~handled_errors:[ ("A pull request already exists", `Already_exists) ]

    let number json =
      handle_errors json
        ~try_:(Json.int_field ~field:"number")
        ~on_ok:(fun x -> x)
        ~default_msg:"Could not retrieve pull request number from response"
        ~handled_errors:[]
  end
end
