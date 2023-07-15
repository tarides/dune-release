open Lwt.Syntax
open Cohttp_lwt_unix
open Cohttp_lwt
module U = Yojson.Safe.Util

let ( / ) a b = U.member b a

let headers accept =
  Cohttp.Header.of_list
    [
      ("Authorization", "bearer " ^ Lazy.force Github.Token.t);
      ("User-Agent", "caretaker");
      ("Accept", accept);
    ]

type t = {
  number : int;
  issue_id : string;
  url : string;
  title : string;
  body : string;
  closed : bool;
  mutable tracks : string list;
}

let number t = t.number
let id t = t.issue_id
let closed t = t.closed
let url t = t.url
let body t = t.body
let title t = t.title
let pp ppf i = Fmt.pf ppf "'#%d: %s'" i.number i.title
let tracks t = t.tracks

let copy_tracks ~src ~dst =
  assert (src.number = dst.number);
  dst.tracks <- src.tracks

let tracks_of_body body =
  let open Astring in
  match String.cut ~sep:"```[tasklist]" body with
  | None -> []
  | Some (_, str) -> (
      let str =
        match String.cut ~sep:"\n```" str with None -> str | Some (p, _) -> p
      in
      match String.cuts ~empty:true ~sep:"\n- [ ] " str with
      | [] -> []
      | _ :: t -> List.map String.trim t)

let v ?(title = "") ?(body = "") ?(url = "") ?(closed = false) number =
  let tracks = tracks_of_body body in
  { number; issue_id = ""; title; body; tracks; closed; url }

let body_of_tracks body tracks =
  let open Astring in
  let old_tracks, prefix, header, suffix =
    match String.cut ~sep:"```[tasklist]" body with
    | None -> (None, body, "", "")
    | Some (prefix, str) -> (
        let str, suffix =
          match String.cut ~sep:"\n```\n" str with
          | None -> (str, "")
          | Some (p, suffix) -> (p, suffix)
        in
        match String.cuts ~empty:true ~sep:"\n- [ ] " str with
        | [] -> (Some [], prefix, "", suffix)
        | header :: t -> (Some t, prefix, header, suffix))
  in
  let pp_tracks = Fmt.(list ~sep:(any "\n- [ ] ") string) in
  if Some tracks = old_tracks then body
  else
    match tracks with
    | [] -> Fmt.str "%s" prefix
    | _ ->
        Fmt.str "%s```[tasklist]%s\n- [ ] %a\n```\n%s" prefix header pp_tracks
          tracks suffix

let normalise_title =
  Re.replace Re.(compile (str "\226\128\153")) ~f:(fun _ -> "'")

let of_json json =
  let title = json |> U.member "title" |> U.to_string |> normalise_title in
  let issue_id = json |> U.member "id" |> U.to_string in
  let number = json |> U.member "number" |> U.to_int in
  let body = json |> U.member "body" |> U.to_string in
  let url = json |> U.member "url" |> U.to_string in
  let closed = json |> U.member "state" |> U.to_string |> ( = ) "CLOSED" in
  let tracks = tracks_of_body body in
  { title; closed; issue_id; number; tracks; body; url }

let to_json t =
  `Assoc
    [
      ("title", `String t.title);
      ("id", `String t.issue_id);
      ("number", `Int t.number);
      ("body", `String t.body);
      ("url", `String t.url);
      ("state", `String (if t.closed then "CLOSED" else "OPEN"));
    ]

let list ~org ~repo () =
  let query cursor =
    let cursor =
      match cursor with None -> "" | Some c -> Fmt.str ", after: %S" c
    in
    Fmt.str
      {|
query {
  repository(owner: %S, name: %S) {
    issues(first: 100%s, states: [OPEN, CLOSED]) {
      pageInfo {
        endCursor
        hasNextPage
      }
      edges {
        node {
          id
          number
          title
          url
          body
          state
        }
      }
    }
  }
}
|}
      org repo cursor
  in
  let rec aux acc cursor =
    let* json = Github.run (query cursor) in
    let json = json / "data" / "repository" / "issues" in
    let page_info = json / "pageInfo" in
    let has_next_page = page_info / "hasNextPage" = `Bool true in
    let cursor = page_info / "endCursor" |> U.to_string in
    let edges = json / "edges" |> U.to_list in
    let issues = List.map (fun json -> of_json (json / "node")) edges in
    let acc = issues @ acc in
    if has_next_page then aux acc (Some cursor) else Lwt.return acc
  in
  aux [] None

let with_tracks i tracks =
  let tracks = List.sort_uniq String.compare tracks in
  let body = body_of_tracks i.body tracks in
  { i with body; tracks }

let update i =
  let query =
    Fmt.str
      {|
mutation {
  updateIssue(input:{
      id:%S,
      body:%S}
    ) {
    issue {
      id
    }
  }
}
|}
      i.issue_id i.body
  in
  let+ _ = Github.run query in
  ()

let update_state ~issue_id = function
  | `Open ->
      Fmt.str
        {|
    mutation { reopenIssue(input: {issueId: %S}) { clientMutationId } }
|}
        issue_id
  | `Closed ->
      Fmt.str
        {|
    mutation { closeIssue(input: {issueId: %S}) { clientMutationId } }
|}
        issue_id

let rec create n org repo title body_str =
  let of_json json =
    let title = json |> U.member "title" |> U.to_string |> normalise_title in
    let issue_id = json |> U.member "node_id" |> U.to_string in
    let number = json |> U.member "number" |> U.to_int in
    let url = json |> U.member "url" |> U.to_string in
    { title; issue_id; number; tracks = []; body = ""; url; closed = false }
  in
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
      let json = Yojson.Safe.from_string body in
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
