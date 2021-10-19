open Bos_setup

let is_handled errors (affix, _) =
  List.exists
    (fun error ->
      match Json.string_field ~field:"message" error with
      | Ok x -> String.is_prefix ~affix x
      | Error _ -> false)
    errors

let pp_errors fs errors =
  List.iter
    (fun error ->
      match Json.string_field ~field:"message" error with
      | Ok message -> Fmt.string fs message
      | Error _ -> ())
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
          R.error_msgf "@[<v 2>Github API error:@ %s@;Github API returned: %a@]"
            default_msg pp_errors errors)

let with_auth ~token Curl.{ url; meth; args } =
  Curl.
    {
      url;
      meth;
      args = Curl_option.Header (strf "Authorization: bearer %s" token) :: args;
    }

let client = "dune-release"
let url = "https://api.github.com/graphql"

module Pull_request = struct
  module Request = struct
    let node_id ~user ~repo ~id =
      let json =
        strf
          {|{ "query": "query { repository(owner:\"%s\", name:\"%s\") { pullRequest(number:%i) { id } } }" }|}
          user repo id
      in
      let args = Curl_option.[ Data (`Data json) ] in
      Curl.{ url; meth = `POST; args }

    let ready_for_review ~node_id =
      let json =
        strf
          {|{ "query": "mutation { markPullRequestReadyForReview (input : {clientMutationId:\"%s\",pullRequestId:\"%s\"}) { pullRequest { url } } }" }|}
          client node_id
      in
      let args = Curl_option.[ Data (`Data json) ] in
      Curl.{ url; meth = `POST; args }
  end

  module Response = struct
    let node_id json =
      let default_msg = "Could not retrieve node_id from pull request" in
      let try_ json =
        match
          Yojson.Basic.Util.member "data" json
          |> Yojson.Basic.Util.member "repository"
          |> Yojson.Basic.Util.member "pullRequest"
          |> Json.string_field ~field:"id"
        with
        | exception _ -> R.error_msg default_msg
        | Ok node_id -> Ok node_id
        | Error _ -> R.error_msg default_msg
      in
      handle_errors json ~try_
        ~on_ok:(fun x -> x)
        ~default_msg ~handled_errors:[]

    let url json =
      let default_msg = "Could not retrieve url from pull request" in
      let try_ json =
        match
          Yojson.Basic.Util.member "data" json
          |> Yojson.Basic.Util.member "markPullRequestReadyForReview"
          |> Yojson.Basic.Util.member "pullRequest"
          |> Json.string_field ~field:"url"
        with
        | exception _ -> R.error_msg default_msg
        | Ok node_id -> Ok node_id
        | Error _ -> R.error_msg default_msg
      in
      handle_errors json ~try_
        ~on_ok:(fun x -> x)
        ~default_msg ~handled_errors:[]
  end
end
