open Lwt.Syntax
open Cohttp_lwt_unix
open Cohttp_lwt
module U = Yojson.Basic.Util

let headers accept =
  Cohttp.Header.of_list
    [
      ("Authorization", "bearer " ^ Github.Token.t);
      ("User-Agent", "caretaker");
      ("Accept", accept);
    ]

type t = { number : int; issue_id : string; title : string }

let number t = t.number
let id t = t.issue_id
let title t = t.title
let pp ppf i = Fmt.pf ppf "'#%d: %s'" i.number i.title

let of_json json =
  let title = json |> U.member "title" |> U.to_string in
  let issue_id = json |> U.member "node_id" |> U.to_string in
  let number = json |> U.member "number" |> U.to_int in
  { title; issue_id; number }

let list ~org ~repo () =
  let uri page =
    Fmt.kstr Uri.of_string
      "https://api.github.com/repos/%s/%s/issues?page=%d&per_page=100" org repo
      page
  in
  let headers = headers "application/vnd.github.v3+json" in
  let rec aux acc page =
    let* resp, body = Client.get ~headers (uri page) in
    match Response.status resp with
    | `OK -> (
        let* body = Body.to_string body in
        let json = Yojson.Basic.from_string body in
        match U.(json |> to_list) with
        | [] -> Lwt.return (List.sort compare (List.flatten acc))
        | issues ->
            let acc = List.map of_json issues :: acc in
            aux acc (page + 1))
    | status ->
        Lwt.fail_with
          (Printf.sprintf "Failed to get issues: HTTP %s"
             (Cohttp.Code.string_of_status status))
  in
  aux [] 1

let rec create n org repo title body_str =
  Fmt.pr "CREATE %s\n%!" title;
  let uri =
    Fmt.kstr Uri.of_string "https://api.github.com/repos/%s/%s/issues" org repo
  in
  let headers = headers "application/vnd.github+json" in
  let body = `Assoc [ ("title", `String title); ("body", `String body_str) ] in
  let body = Yojson.to_string body in
  let* resp, body = Client.post ~headers ~body:(Body.of_string body) uri in
  match Cohttp.Response.status resp with
  | `OK | `Created ->
      let+ body = Body.to_string body in
      let json = Yojson.Basic.from_string body in
      of_json json
  | `Forbidden ->
      let retry_after =
        match Cohttp.Header.get resp.headers "retry-after" with
        | None -> n * 10
        | Some d -> int_of_string d
      in
      Fmt.pr "...SLEEP FOR %ds...\n%!" retry_after;
      Unix.sleep retry_after;
      create (n + 1) org repo title body_str
  | e ->
      Fmt.failwith "Failed to create issue: %s" (Cohttp.Code.string_of_status e)

let create ~org ~repo ~title ~body () = create 1 org repo title body
