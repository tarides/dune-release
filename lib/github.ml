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

let run query =
  Fmt.pr "Querying Github...\n%!";
  if Hashtbl.mem cache query then Lwt.return (Hashtbl.find cache query)
  else (
    if debug then Fmt.epr "QUERY: %s\n%!" query;
    let token = Lazy.force Token.t in
    let request = Get_activity.Graphql.request ~token ~query () in
    let response =
      match Get_activity.Graphql.exec request with
      | Ok resp -> resp
      | Error (`Msg msg) ->
          Fmt.failwith "@[<v2>Error performing GraphQL query on GitHub: %s@]"
            msg
    in
    Hashtbl.add cache query response;
    Lwt.return response)
