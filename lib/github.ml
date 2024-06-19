module Token = struct
  let token = ref None
  let set x = token := Some x
  let github_token_env () = Sys.getenv_opt "GITHUB_TOKEN"

  let github_token_file () =
    let f = Sys.getenv "HOME" ^ "/.github/github-activity-token" in
    let ic = open_in f in
    let n = in_channel_length ic in
    String.trim (really_input_string ic n)

  let t =
    lazy
      (match !token with
      | Some x -> x
      | None -> (
          match github_token_env () with
          | Some x -> x
          | None -> github_token_file ()))
end

module U = Yojson.Safe.Util

let cache = Hashtbl.create 128

let debug =
  match Sys.getenv "GH_DEBUG" with
  | "" | "0" | "false" -> false
  | _ -> true
  | exception Not_found -> false

module Graphql = struct
  (* copy from get-activity *)
  let ( / ) a b = Yojson.Safe.Util.member b a

  type request = {
    meth : Curly.Meth.t;
    url : string;
    headers : Curly.Header.t;
    body : Yojson.Safe.t;
  }

  let request ?variables ~token ~query () =
    let body =
      `Assoc
        (("query", `String query)
        ::
        (match variables with
        | None -> []
        | Some v -> [ ("variables", `Assoc v) ]))
    in
    let url = "https://api.github.com/graphql" in
    let headers = [ ("Authorization", "bearer " ^ token) ] in
    { meth = `POST; url; headers; body }

  let ratelimit_remaining = ref None

  let update_ratelimit_remaining headers =
    match List.assoc_opt "x-ratelimit-remaining" headers with
    | Some x -> ratelimit_remaining := Some (int_of_string x)
    | None -> ()

  let exec request =
    let { meth; url; headers; body } = request in
    let body = Yojson.Safe.to_string body in
    let request = Curly.Request.make ~headers ~body ~url ~meth () in
    Logs.debug (fun m -> m "request: @[%a@]@." Curly.Request.pp request);
    match Curly.run request with
    | Ok ({ Curly.Response.body; headers; _ } as response) -> (
        update_ratelimit_remaining headers;
        Logs.debug (fun m -> m "response: @[%a@]@." Curly.Response.pp response);
        let json = Yojson.Safe.from_string body in
        match json / "message" with
        | `Null -> Ok json
        | `String e ->
            Error
              (`Msg (Format.asprintf "@[<v2>GitHub returned errors: %s@]" e))
        | _errors ->
            Error
              (`Msg
                (Format.asprintf "@[<v2>GitHub returned errors: %a@]"
                   (Yojson.Safe.pretty_print ~std:true)
                   json)))
    | Error e ->
        Error
          (`Msg
            (Format.asprintf
               "@[<v2>Error performing GraphQL query on GitHub: %a@]"
               Curly.Error.pp e))
end

let pp_ratelimit_remaining ppf () =
  match !Graphql.ratelimit_remaining with
  | None -> ()
  | Some i -> Fmt.pf ppf "(remaining points: %d)" i

let run query =
  Fmt.pr "Querying Github %a... \n%!" pp_ratelimit_remaining ();
  if Hashtbl.mem cache query then Lwt.return (Hashtbl.find cache query)
  else (
    if debug then Fmt.epr "QUERY: %s\n%!" query;
    let token = Lazy.force Token.t in
    let request = Graphql.request ~token ~query () in
    let response =
      match Graphql.exec request with
      | Ok resp -> resp
      | Error (`Msg msg) ->
          Fmt.failwith "@[<v2>Error performing GraphQL query on GitHub: %s@]"
            msg
    in
    Hashtbl.add cache query response;
    Lwt.return response)
