module Token = struct
  let github_token_env () = Sys.getenv_opt "GITHUB_TOKEN"

  let github_token_file () =
    let f = Sys.getenv "HOME" ^ "/.github/github-activity-token" in
    let ic = open_in f in
    let n = in_channel_length ic in
    String.trim (really_input_string ic n)

  let t =
    lazy
      (match github_token_env () with
      | Some x -> x
      | None -> github_token_file ())
end

module U = Yojson.Safe.Util

let ( / ) a b = U.member b a
let cache = Hashtbl.create 128
let graphql_endpoint = "https://api.github.com/graphql"

let debug =
  match Sys.getenv "GH_DEBUG" with
  | "" | "0" | "false" -> false
  | _ -> true
  | exception Not_found -> false

let run query =
  Fmt.pr "Querying Github...\n%!";
  if Hashtbl.mem cache query then Lwt.return (Hashtbl.find cache query)
  else
    let open Lwt.Syntax in
    if debug then Fmt.epr "QUERY: %s\n%!" query;
    let body =
      `Assoc [ ("query", `String query) ]
      |> Yojson.Safe.to_string |> Cohttp_lwt.Body.of_string
    in
    let headers =
      Cohttp.Header.init_with "Authorization" ("bearer " ^ Lazy.force Token.t)
    in
    let* resp, body =
      Cohttp_lwt_unix.Client.post ~headers ~body
        (Uri.of_string graphql_endpoint)
    in
    let+ body = Cohttp_lwt.Body.to_string body in
    let response =
      match Cohttp.Response.status resp with
      | `OK -> (
          let json = Yojson.Safe.from_string body in
          match json / "errors" with
          | `Null -> json
          | _errors ->
              Fmt.failwith "@[<v2>GitHub returned errors: %a@]"
                (Yojson.Safe.pretty_print ~std:true)
                json)
      | err ->
          Fmt.failwith
            "@[<v2>Error performing GraphQL query on GitHub: %s@,%s@]"
            (Cohttp.Code.string_of_status err)
            body
    in
    Hashtbl.add cache query response;
    response
