(*
 * Copyright (c) 2018 Thomas Gazagnaire <thomas@gazagnaire.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

open Bos_setup

module Dry_run = struct
  let token = "${token}"
end

type t = {
  user : string option;
  remote : string;
  local : Fpath.t;
  keep_v : bool option;
  auto_open : bool option;
}

module Opam_repo_fork = struct
  type t = { remote : string; local : Fpath.t; user : string option }
end

let of_yaml_exn str =
  (* ouch *)
  let lines = String.cuts ~empty:false ~sep:"\n" str in
  let dict () =
    List.map
      (fun line ->
        match String.cut ~sep:":" line with
        | Some (k, v) -> (String.trim k, String.trim v)
        | _ -> failwith "invalid format")
      lines
  in
  let dict = dict () in
  let find k = try Some (List.assoc k dict) with Not_found -> None in
  let find_b k =
    match find k with None -> None | Some s -> Some (bool_of_string s)
  in
  let valid = [ "user"; "remote"; "local"; "auto-open"; "keep-v" ] in
  List.iter
    (fun (k, _) ->
      if not (List.mem k valid) then
        Fmt.failwith "%S is not a valid configuration key." k)
    dict;
  let opam_repo_fork =
    match (find "local", find "remote") with
    | Some local_str, Some remote ->
        Fpath.of_string local_str >>| fun local -> (local, remote)
    | _ ->
        Rresult.R.error_msg
          "Dune-release configuration file is compromised: both local and \
           remote field should be set"
  in
  opam_repo_fork >>| fun (local, remote) ->
  {
    user = find "user";
    remote;
    local;
    auto_open = find_b "auto-open";
    keep_v = find_b "keep-v";
  }

let of_yaml str = try of_yaml_exn str with Failure s -> R.error_msg s
let config_dir () = Ok Fpath.(v Xdg.config_dir / "dune")
let get_path () = config_dir () >>| fun cfg -> Fpath.(cfg / "release.yml")

let load () =
  get_path () >>= fun file ->
  OS.File.exists file >>= fun exists ->
  if exists then OS.File.read file >>= of_yaml >>| fun x -> Some x else Ok None

let pretty_fields { user; remote; local; keep_v; auto_open } =
  [
    ("user", user);
    ("remote", Some remote);
    ("local", Some (Fpath.to_string local));
    ("keep-v", Stdext.Option.map ~f:string_of_bool keep_v);
    ("auto-open", Stdext.Option.map ~f:string_of_bool auto_open);
  ]

let save t =
  get_path () >>= fun file ->
  let fields = pretty_fields t in
  let content =
    let open Stdext in
    List.filter_map fields ~f:(function
      | _, None -> None
      | f, Some v -> Some (Printf.sprintf "%s: %s" f v))
  in
  OS.File.write_lines file content

let create_config ?(pkgs = []) file =
  App_log.status (fun l -> l "%a does not exist!" Fpath.pp file);
  App_log.status (fun l ->
      l "Please answer a few questions so we can create it for you:");
  App_log.blank_line ();
  let guessed_user =
    match pkgs with
    | [] -> None
    | pkg :: _ ->
        let res = Pkg.infer_github_repo pkg >>= fun { owner; _ } -> Ok owner in
        Rresult.R.to_option res
  in
  let default_remote =
    let open Stdext.Option.O in
    guessed_user >|= fun user -> strf "git@github.com:%s/opam-repository" user
  in
  let default_local =
    Fpath.(v Xdg.home / "git" / "opam-repository" |> to_string)
  in
  let remote =
    Prompt.user_input ?default_answer:default_remote
      ~question:
        "What is your fork of ocaml/opam-repository? (you should have write \
         access)."
      ()
  in
  let local =
    Prompt.user_input ~default_answer:default_local
      ~question:"Where on your filesystem did you clone that repository?" ()
  in
  Fpath.of_string local >>= fun local ->
  let config =
    { user = None; remote; local; auto_open = None; keep_v = None }
  in
  OS.Dir.create Fpath.(parent file) >>= fun _ ->
  save config >>= fun () -> Ok config

let create ?pkgs () =
  get_path () >>= fun file ->
  create_config ?pkgs file >>= fun _ -> Ok ()

let find () =
  get_path () >>= fun file ->
  OS.File.exists file >>= fun exists ->
  if exists then OS.File.read file >>= of_yaml >>| fun x -> Some x else Ok None

let token_file () = config_dir () >>= fun cfg -> Ok Fpath.(cfg / "github.token")

let get_token () =
  let rec aux () =
    match Stdext.Unix.read_line ~echo_input:false () with
    | "" -> aux ()
    | s -> s
    | exception End_of_file ->
        print_newline ();
        aux ()
    | exception (Sys.Break as e) ->
        print_newline ();
        raise e
  in
  aux ()

let validate_token token =
  let token = String.trim token in
  if String.is_empty token || String.exists Char.Ascii.is_white token then
    Error (R.msg "token is malformed")
  else Ok token

let token_creation_url = "https://github.com/settings/tokens/new"

let prompt_for_token () =
  let rec get_valid_token () =
    match validate_token (get_token ()) with
    | Ok token -> token
    | Error (`Msg msg) ->
        App_log.question (fun l -> l "Please try again, %s" msg);
        get_valid_token ()
  in
  App_log.status (fun l ->
      l
        "Dune-release needs a Github Personal Access Token to proceed with API \
         requests.");
  App_log.status (fun l ->
      l "To create a new token, please visit:\n    %s" token_creation_url);
  App_log.status (fun l ->
      l "and create a token with the %a scope only."
        Fmt.(styled `Bold string)
        "public_repo");
  App_log.question (fun l -> l "Please paste the token here:");
  get_valid_token ()

let config_token ~dry_run () =
  token_file () >>= fun file ->
  OS.File.exists file >>= fun exists ->
  let is_valid =
    if exists then Sos.read_file ~dry_run file >>= validate_token
    else Error (R.msg "file does not exist")
  in
  match is_valid with
  | _ when dry_run -> Ok Dry_run.token
  | Ok token -> Ok token
  | Error (`Msg msg) ->
      let () = App_log.unhappy (fun l -> l "%a: %s" Fpath.pp file msg) in
      let token = prompt_for_token () in
      OS.Dir.create Fpath.(parent file) >>= fun _ ->
      OS.File.write ~mode:0o600 file token >>= fun () -> Ok token

module Cli = struct
  type 'a t = 'a

  let make x = x
end

let token ~token ~dry_run () =
  match token with
  | Some _ when dry_run -> Ok Dry_run.token
  | Some token -> Ok token
  | None -> config_token ~dry_run ()

let file = lazy (find ())

let read f ~default =
  Lazy.force file >>| function
  | None -> default
  | Some t -> ( match f t with None -> default | Some b -> b)

let keep_v ~keep_v =
  if keep_v then Ok true else read (fun t -> t.keep_v) ~default:false

let auto_open ~no_auto_open =
  if no_auto_open then Ok false else read (fun t -> t.auto_open) ~default:true

let opam_repo_fork ?pkgs ~user ~remote ~local () =
  match (remote, local, user) with
  | Some remote, Some local, Some user ->
      Ok { Opam_repo_fork.remote; local; user }
  | _ ->
      let config =
        Lazy.force file >>= function
        | Some x -> Ok x
        | None -> get_path () >>= create_config ?pkgs
      in
      config >>= fun config ->
      let local = Stdext.Option.value ~default:config.local local in
      let remote = Stdext.Option.value ~default:config.remote remote in
      let user = Stdext.Option.value ~default:config.user user in
      Ok { Opam_repo_fork.remote; local; user }

module type S = sig
  val path : build_dir:Fpath.t -> name:string -> version:Version.t -> Fpath.t

  val set :
    dry_run:bool ->
    build_dir:Fpath.t ->
    name:string ->
    version:Version.t ->
    string ->
    (unit, R.msg) result

  val is_set :
    dry_run:bool ->
    build_dir:Fpath.t ->
    name:string ->
    version:Version.t ->
    (bool, R.msg) result

  val get :
    dry_run:bool ->
    build_dir:Fpath.t ->
    name:string ->
    version:Version.t ->
    (string, R.msg) result

  val unset :
    dry_run:bool ->
    build_dir:Fpath.t ->
    name:string ->
    version:Version.t ->
    (unit, R.msg) result
end

module Make (X : sig
  val ext : string
end) =
struct
  let path ~build_dir ~name ~version =
    Fpath.(build_dir / strf "%s-%a.%s" name Version.pp version X.ext)

  let set ~dry_run ~build_dir ~name ~version id =
    Sos.write_file ~dry_run (path ~build_dir ~name ~version) id

  let is_set ~dry_run ~build_dir ~name ~version =
    Sos.file_exists ~dry_run (path ~build_dir ~name ~version)

  let get ~dry_run ~build_dir ~name ~version =
    Sos.read_file ~dry_run (path ~build_dir ~name ~version)

  let unset ~dry_run ~build_dir ~name ~version =
    let path = path ~build_dir ~name ~version in
    Sos.file_exists ~dry_run path >>= fun exists ->
    if exists then Sos.delete_path ~dry_run path else Ok ()
end

module Draft_release = Make (struct
  let ext = "draft_release"
end)

module Draft_pr = Make (struct
  let ext = "draft_pr"
end)

module Release_asset_name = Make (struct
  let ext = "release_asset_name"
end)
