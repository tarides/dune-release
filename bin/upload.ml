open Lwt.Syntax
open Caretaker
open Cohttp_lwt_unix
open Cohttp_lwt
module U = Yojson.Basic.Util

let () =
  Fmt_tty.setup_std_outputs ();
  Logs.set_level ~all:true (Some Logs.Debug)

type conf = { owner : string; repo : string; project_id : int }
type entry = { objective : string; team : string; status : string }

let headers accept =
  Cohttp.Header.of_list
    [
      ("Authorization", "bearer " ^ Github.Token.t);
      ("User-Agent", "caretaker");
      ("Accept", accept);
    ]

type issue = { number : int; issue_id : string; title : string }

let _pp_issue ppf i = Fmt.pf ppf "'#%d: %s'" i.number i.title

let issue_of_json json =
  let title = json |> U.member "title" |> U.to_string in
  let issue_id = json |> U.member "node_id" |> U.to_string in
  let number = json |> U.member "number" |> U.to_int in
  { title; issue_id; number }

let compare_issue x y =
  match String.compare x.title y.title with
  | 0 -> compare x.number y.number
  | i -> i

let _delete_issue conf issue =
  let uri =
    Fmt.kstr Uri.of_string "https://api.github.com/repos/%s/%s/issues/%d"
      conf.owner conf.repo issue.number
  in
  let headers = headers "application/vnd.github.v3+json" in
  let* resp, _body = Client.delete ~headers uri in
  match Response.status resp with
  | `OK -> Lwt.return ()
  | status ->
      Lwt.fail_with
        (Printf.sprintf "Failed to get issues: HTTP %s"
           (Cohttp.Code.string_of_status status))

let find_duplicates conf l =
  let l = List.sort compare_issue l in
  let rec aux = function
    | [] | [ _ ] -> ()
    | a :: b :: t ->
        if a.title = b.title then (
          assert (b.number > a.number);
          Fmt.pr "DUPLICATE: https://github.com/%s/%s/issues/%d\n%!" conf.owner
            conf.repo b.number;
          aux (a :: t))
        else aux (b :: t)
  in
  aux l

let list_issues conf =
  let uri page =
    Fmt.kstr Uri.of_string
      "https://api.github.com/repos/%s/%s/issues?page=%d&per_page=100"
      conf.owner conf.repo page
  in
  let headers = headers "application/vnd.github.v3+json" in
  let rec aux acc page =
    let* resp, body = Client.get ~headers (uri page) in
    match Response.status resp with
    | `OK -> (
        let* body = Body.to_string body in
        let json = Yojson.Basic.from_string body in
        match U.(json |> to_list) with
        | [] -> Lwt.return (List.sort compare_issue (List.flatten acc))
        | issues ->
            let acc = List.map issue_of_json issues :: acc in
            aux acc (page + 1))
    | status ->
        Lwt.fail_with
          (Printf.sprintf "Failed to get issues: HTTP %s"
             (Cohttp.Code.string_of_status status))
  in
  aux [] 1

let rec create_issue n conf title body_str =
  Fmt.pr "CREATE %s\n%!" title;
  let uri =
    Fmt.kstr Uri.of_string "https://api.github.com/repos/%s/%s/issues"
      conf.owner conf.repo
  in
  let headers = headers "application/vnd.github+json" in
  let body = `Assoc [ ("title", `String title); ("body", `String body_str) ] in
  let body = Yojson.to_string body in
  let* resp, body = Client.post ~headers ~body:(Body.of_string body) uri in
  match Cohttp.Response.status resp with
  | `OK | `Created ->
      let+ body = Body.to_string body in
      let json = Yojson.Basic.from_string body in
      U.(json |> member "node_id" |> to_string)
  | `Forbidden ->
      let retry_after =
        match Cohttp.Header.get resp.headers "retry-after" with
        | None -> n * 10
        | Some d -> int_of_string d
      in
      Fmt.pr "...SLEEP FOR %ds...\n%!" retry_after;
      Unix.sleep retry_after;
      create_issue (n + 1) conf title body_str
  | e ->
      Fmt.failwith "Failed to create issue: %s" (Cohttp.Code.string_of_status e)

let add_issue_to_project ~project_id ~issue_id =
  let uri = Uri.of_string "https://api.github.com/graphql" in
  let headers = headers "application/vnd.github.inertia-preview+json" in
  let query =
    Printf.sprintf
      {|
      mutation {
        addProjectV2ItemById(input: {projectId: %S contentId: %S}) {
          item {
            id
          }
        }
      }
  |}
      project_id issue_id
  in
  let body = `Assoc [ ("query", `String query) ] in
  let body = Yojson.to_string body in
  let* resp, body =
    Cohttp_lwt_unix.Client.post ~headers
      ~body:(Cohttp_lwt.Body.of_string body)
      uri
  in
  match Cohttp.Response.status resp with
  | `OK ->
      let+ body = Cohttp_lwt.Body.to_string body in
      let json = Yojson.Basic.from_string body in
      U.(
        json |> member "data"
        |> member "addProjectV2ItemById"
        |> member "item" |> member "id" |> to_string)
  | _ -> failwith "Failed to add issue to project"

let of_csv file =
  let ic = open_in file in
  let res = ref [] in
  let rows = Csv.of_channel ~has_header:true ic in
  let () =
    match Csv.Rows.header rows with
    | [ "Objective"; "Team"; "Status" ] -> ()
    | _ -> Fmt.invalid_arg "invalid headers"
  in
  Csv.Rows.iter
    ~f:(fun row ->
      match Csv.Row.to_list row with
      | [ o; t; s ] ->
          let e =
            {
              objective = String.trim o;
              team = String.trim t;
              status = String.trim s;
            }
          in
          res := e :: !res
      | l -> Fmt.epr "Warning; invalid line: %a\n" Fmt.(Dump.list string) l)
    rows;
  close_in ic;
  !res

let update_project fields ~issue_id ~project_id e =
  let* card_id = add_issue_to_project ~project_id ~issue_id in
  let update_status =
    Card.Raw.graphql_mutate ~fields ~project_id ~card_id
      (Column.of_string "status")
      e.status
  in

  let update_team =
    Card.Raw.graphql_mutate ~fields ~project_id ~card_id
      (Column.of_string "team") e.team
  in
  let* _ = Github.run update_status in
  let+ _ = Github.run update_team in
  ()

let create_issue conf e = create_issue 1 conf e.objective ""

let run ~force () =
  let entries = of_csv "input.csv" in
  let conf = { owner = "tarides"; repo = "goals"; project_id = 27 } in
  let* issues = list_issues conf in
  let* project_id, fields =
    Project.get_id_and_fields ~org:conf.owner ~project_number:conf.project_id
  in
  find_duplicates conf issues;
  Lwt_list.iter_s
    (fun e ->
      match List.find_opt (fun i -> e.objective = i.title) issues with
      | None ->
          let* issue_id = create_issue conf e in
          update_project fields ~project_id ~issue_id e
      | Some { issue_id; _ } ->
          if force then update_project fields ~issue_id ~project_id e
          else Lwt.return ())
    entries

let () = Lwt_main.run (run ~force:false ())
