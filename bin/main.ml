open Caretaker
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

let pp_csv_ts ppf t = Fmt.string ppf (Report.to_csv t)

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

let read_file f =
  let ic = open_in f in
  let s = really_input_string ic (in_channel_length ic) in
  close_in ic;
  s

let read_timesheets ~years ~months okr_updates_dir =
  let ( / ) = Filename.concat in
  List.fold_left
    (fun acc year ->
      let root = okr_updates_dir / "team-weeklies" / string_of_int year in
      List.fold_left
        (fun acc month ->
          let dir = Fmt.str "%s/%02d" root month in
          if (not (Sys.file_exists dir)) || not (Sys.is_directory dir) then acc
          else
            let files =
              Sys.readdir dir |> Array.to_list
              |> List.filter (fun file -> String.ends_with ~suffix:".md" file)
            in
            List.fold_left
              (fun acc file ->
                let str = read_file (dir / file) in
                Report.of_markdown ~acc ~year ~month str)
              acc files)
        acc months)
    (Hashtbl.create 13) years

let query_github ~token org project_numbers : t Lwt.t =
  let+ projects =
    Lwt_list.map_p
      (fun project_number ->
        let+ json = exec ~token (query org project_number) in
        if debug then Fmt.epr "Result: %a\n" Yojson.Safe.pp json;
        Project.parse json)
      project_numbers
  in
  { org; projects }

let filter ?filter_out data =
  let filter = Project.filter ?filter_out in
  { data with projects = List.map filter data.projects }

let out ~format t =
  match format with
  | `Plain -> Fmt.pr "%a\n%!" pp t
  | `CSV -> Fmt.pr "%a\n%!" pp_csv t

let out_ts t = Fmt.pr "%a\n%!" pp_csv_ts t

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

let okr_updates_dir_term =
  let env = Cmd.Env.info ~doc:"PATH" "OKR_UPDATES_DIR" in
  Arg.(
    value
    @@ opt (some string) None
    @@ info ~env ~doc:"Path to the okr-updates repository" [ "okr-updates-dir" ])

let timesheets_term =
  Arg.(value @@ flag @@ info ~doc:"Manage timesheets" [ "timesheets"; "t" ])

let setup =
  let style_renderer = Fmt_cli.style_renderer () in
  Term.(
    const (fun style_renderer -> Fmt_tty.setup_std_outputs ?style_renderer ())
    $ style_renderer)

let projects () format org project_numbers okr_updates_dir timesheets =
  if timesheets then
    match okr_updates_dir with
    | None ->
        failwith
          "Please set-up OKR_UPDATES_DIR to point to your local copy of the \
           okr-updates repositories"
    | Some okr_updates_dir ->
        let ts =
          read_timesheets ~years:[ 2023 ]
            ~months:[ 0; 1; 2; 3; 4; 5; 6; 7; 8; 9; 10 ]
            okr_updates_dir
        in
        out_ts ts
  else
    Lwt_main.run
    @@ let+ data = query_github ~token org project_numbers in
       let data = filter data in
       out ~format data

let cmd =
  Cmd.v (Cmd.info "gh-projects")
    Term.(
      const projects $ setup $ format $ org_term $ project_numbers_term
      $ okr_updates_dir_term $ timesheets_term)

let () = exit (Cmd.eval cmd)
