open Lwt.Syntax
open Cohttp_lwt_unix
module U = Yojson.Safe.Util

let ( / ) a b = U.member b a

let debug =
  match Sys.getenv "GH_DEBUG" with
  | "" | "0" | "false" -> false
  | _ -> true
  | exception Not_found -> false

type t = { org : string; projects : Project.t list }

let pp ppf t =
  Fmt.pf ppf "org: %s\n" t.org;
  List.iter (Project.pp ppf) t.projects

let pp_csv ppf t =
  List.iter (fun p -> Fmt.string ppf (Project.to_csv p)) t.projects

let query org project_id =
  Fmt.str
    {| query{
  organization(login: %S) {
      %s
  }
    }
  |}
    org
    (Project.graphql project_id)

let token =
  let f = Sys.getenv "HOME" ^ "/.github/github-activity-token" in
  let ic = open_in f in
  let n = in_channel_length ic in
  String.trim (really_input_string ic n)

let graphql_endpoint = Uri.of_string "https://api.github.com/graphql"

let exec ~token query =
  if debug then Fmt.epr "QUERY: %s\n" query;
  let body =
    `Assoc [ ("query", `String query) ]
    |> Yojson.Safe.to_string |> Cohttp_lwt.Body.of_string
  in
  let headers = Cohttp.Header.init_with "Authorization" ("bearer " ^ token) in
  let* resp, body = Client.post ~headers ~body graphql_endpoint in
  let+ body = Cohttp_lwt.Body.to_string body in
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
      Fmt.failwith "@[<v2>Error performing GraphQL query on GitHub: %s@,%s@]"
        (Cohttp.Code.string_of_status err)
        body

let get ~token org project_numbers : t Lwt.t =
  let+ projects =
    Lwt_list.map_p
      (fun project_number ->
        let+ json = exec ~token (query org project_number) in
        if debug then Fmt.epr "Result: %a\n" Yojson.Safe.pp json;
        Project.parse json)
      project_numbers
  in
  { org; projects }

let out ~format t =
  match format with
  | `Plain -> Fmt.pr "%a\n%!" pp t
  | `CSV -> Fmt.pr "%a\n%!" pp_csv t

open Cmdliner

let org_term =
  Arg.(
    value @@ pos 0 string "tarides"
    @@ info ~doc:"The organisation to get projects from" ~docv:"ORG" [])

let project_numbers_term =
  Arg.(
    value
    @@ opt (list int) [ 5; 20 ]
    @@ info ~doc:"The project IDS" ~docv:"IDs" [ "number"; "n" ])

let format =
  Arg.(
    value
    @@ opt (enum [ ("plain", `Plain); ("csv", `CSV) ]) `Plain
    @@ info ~doc:"The output format" [ "format"; "f" ])

let setup =
  let style_renderer = Fmt_cli.style_renderer () in
  Term.(
    const (fun style_renderer -> Fmt_tty.setup_std_outputs ?style_renderer ())
    $ style_renderer)

let projects () format org project_numbers =
  Lwt_main.run
  @@ let+ data = get ~token org project_numbers in
     out ~format data

let cmd =
  Cmd.v (Cmd.info "gh-projects")
    Term.(const projects $ setup $ format $ org_term $ project_numbers_term)

let () = exit (Cmd.eval cmd)
