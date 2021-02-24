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

type t = {
  user : string option;
  remote : string option;
  local : Fpath.t option;
  keep_v : bool option;
  auto_open : bool option;
}

let empty =
  { user = None; remote = None; local = None; keep_v = None; auto_open = None }

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
  let local =
    match find "local" with
    | None -> None
    | Some v -> (
        match Fpath.of_string v with Ok x -> Some x | Error _ -> None)
  in
  {
    user = find "user";
    remote = find "remote";
    local;
    auto_open = find_b "auto-open";
    keep_v = find_b "keep-v";
  }

let of_yaml str = try Ok (of_yaml_exn str) with Failure s -> R.error_msg s

let read_string default ~descr =
  let read () =
    match read_line () with
    | "" -> None
    | s ->
        print_newline ();
        Some s
    | exception End_of_file ->
        print_newline ();
        None
    | exception (Sys.Break as e) ->
        print_newline ();
        raise e
  in
  Fmt.pr "@[<h-0>%s@.[press ENTER to use '%a']@]\n%!" (String.trim descr)
    Fmt.(styled `Bold string)
    default;
  match read () with None -> default | Some s -> s

let create_config ~user ~remote_repo ~local_repo pkgs file =
  Fmt.pr
    "%a does not exist!\n\
     Please answer a few questions to help me create it for you:\n\n\
     %!"
    Fpath.pp file;
  (match user with
  | Some u -> Ok u
  | None ->
      let pkg = List.hd pkgs in
      Pkg.infer_repo_uri pkg >>= Pkg.user_and_repo_from_uri >>= fun (u, _) ->
      Ok u)
  >>= fun default_user ->
  let user = read_string default_user ~descr:"What is your GitHub ID?" in
  let default_remote =
    match remote_repo with
    | Some r -> r
    | None -> strf "git@github.com:%s/opam-repository" user
  in
  let default_local =
    match local_repo with
    | Some r -> Ok r
    | None -> Ok Fpath.(v Xdg.home / "git" / "opam-repository" |> to_string)
  in
  default_local >>= fun default_local ->
  let remote =
    read_string default_remote
      ~descr:
        "What is your fork of ocaml/opam-repository? (you should have write \
         access)."
  in
  let local =
    read_string default_local
      ~descr:"Where on your filesystem did you clone that repository?"
  in
  Fpath.of_string local >>= fun local ->
  let v = strf "user: %s\nremote: %s\nlocal: %a\n" user remote Fpath.pp local in
  OS.Dir.create Fpath.(parent file) >>= fun _ ->
  OS.File.write file v >>= fun () ->
  Ok
    {
      user = Some user;
      remote = Some remote;
      local = Some local;
      auto_open = None;
      keep_v = None;
    }

let config_dir () =
  let cfg = Fpath.(v Xdg.config_dir / "dune") in
  let upgrade () =
    (* Upgrade from 0.2 to 0.3 format *)
    let old_d = Fpath.(v Xdg.home / ".dune") in
    OS.Dir.exists old_d >>= function
    | false -> Ok ()
    | true ->
        App_log.status (fun m ->
            m "Upgrading configuration files: %a => %a" Fpath.pp old_d Fpath.pp
              cfg);
        OS.Dir.create ~path:true cfg >>= fun _ ->
        OS.Path.move old_d Fpath.(cfg / "release.yml")
  in
  upgrade () >>= fun () -> Ok cfg

let file () = config_dir () >>| fun cfg -> Fpath.(cfg / "release.yml")

let find () =
  file () >>= fun file ->
  OS.File.exists file >>= fun exists ->
  if exists then OS.File.read file >>= of_yaml >>| fun x -> Some x else Ok None

let v ~user ~remote_repo ~local_repo pkgs =
  find () >>= function
  | Some f -> Ok f
  | None -> file () >>= create_config ~user ~remote_repo ~local_repo pkgs

let reset_terminal : (unit -> unit) option ref = ref None

let cleanup () = match !reset_terminal with None -> () | Some f -> f ()

let () = at_exit cleanup

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

let token ~dry_run () =
  config_dir () >>= fun cfg ->
  let file = Fpath.(cfg / "github.token") in
  OS.File.exists file >>= fun exists ->
  let is_valid =
    if exists then Sos.read_file ~dry_run file >>= validate_token
    else Error (R.msg "does not exist")
  in
  match is_valid with
  | Ok _ -> Ok file
  | Error (`Msg msg) ->
      if dry_run then Ok Fpath.(v "${token}")
      else
        let error = if exists then ":" ^ msg else " does not exist" in
        Fmt.pr
          "%a%s!\n\n\
           To create a new token, please visit:\n\n\
          \   https://github.com/settings/tokens/new\n\n\
           And create a token with a nice name and and the %a scope only.\n\n\
           Copy the token@ here: %!" Fpath.pp file error
          Fmt.(styled `Bold string)
          "public_repo";
        let rec get_valid_token () =
          match validate_token (get_token ()) with
          | Ok token -> token
          | Error (`Msg msg) ->
              Fmt.pr "Please try again, %s.%!" msg;
              get_valid_token ()
        in
        let token = get_valid_token () in
        OS.Dir.create Fpath.(parent file) >>= fun _ ->
        OS.File.write ~mode:0o600 file token >>= fun () -> Ok file

let load () =
  file () >>= fun file ->
  OS.File.exists file >>= fun exists ->
  if exists then OS.File.read file >>= of_yaml >>| fun x -> x else Ok empty

let pretty_fields { user; remote; local; keep_v; auto_open } =
  [
    ("user", user);
    ("remote", remote);
    ("local", Stdext.Option.map ~f:Fpath.to_string local);
    ("keep-v", Stdext.Option.map ~f:string_of_bool keep_v);
    ("auto-open", Stdext.Option.map ~f:string_of_bool auto_open);
  ]

let save t =
  file () >>= fun file ->
  let fields = pretty_fields t in
  let content =
    let open Stdext in
    List.filter_map fields ~f:(function
      | _, None -> None
      | f, Some v -> Some (Printf.sprintf "%s: %s" f v))
  in
  OS.File.write_lines file content

let file = lazy (find ())

let read f default =
  Lazy.force file >>| function
  | None -> default
  | Some t -> ( match f t with None -> default | Some b -> b)

let keep_v v = if v then Ok true else read (fun t -> t.keep_v) false

let auto_open v = if not v then Ok false else read (fun t -> t.auto_open) true
