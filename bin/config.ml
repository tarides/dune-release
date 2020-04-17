open Dune_release

let invalid_config_key key =
  Rresult.R.error_msgf "%S is not a valid global config field" key

let show_val = function None -> "<unset>" | Some x -> x

let log_val string_opt =
  Logs.app (fun l -> l "%s" (show_val string_opt));
  Ok ()

let show key =
  let open Rresult.R.Infix in
  Config.load () >>= fun config ->
  match key with
  | None ->
      let pretty_fields = Config.pretty_fields config in
      StdLabels.List.iter pretty_fields ~f:(fun (key, value) ->
          Logs.app (fun l -> l "%s: %s" key (show_val value)));
      Ok ()
  | Some "user" -> log_val config.user
  | Some "remote" -> log_val config.remote
  | Some "local" -> log_val (Stdext.Option.map ~f:Fpath.to_string config.local)
  | Some "keep-v" -> log_val (Stdext.Option.map ~f:string_of_bool config.keep_v)
  | Some "auto-open" ->
      log_val (Stdext.Option.map ~f:string_of_bool config.auto_open)
  | Some key -> invalid_config_key key

let to_bool ~field value =
  match String.lowercase_ascii value with
  | "true" -> Ok true
  | "false" -> Ok false
  | _ -> Rresult.R.error_msgf "Invalid value %S for field %s" value field

let set key value =
  let open Rresult.R.Infix in
  Config.load () >>= fun config ->
  let updated =
    match key with
    | "user" -> Ok { config with user = Some value }
    | "remote" -> Ok { config with remote = Some value }
    | "local" ->
        Fpath.of_string value >>| fun v -> { config with local = Some v }
    | "keep-v" ->
        to_bool ~field:key value >>| fun v -> { config with keep_v = Some v }
    | "auto-open" ->
        to_bool ~field:key value >>| fun v -> { config with auto_open = Some v }
    | _ -> invalid_config_key key
  in
  updated >>= Config.save >>= fun () -> Ok ()

let default_usage ?raw () =
  let cmd = "dune-release config" in
  match raw with Some () -> cmd | None -> Printf.sprintf "$(b,%s)" cmd

let show_usage ?raw () =
  let cmd = "dune-release config show" in
  let key = "KEY" in
  match raw with
  | Some () -> Printf.sprintf "%s [%s]" cmd key
  | None -> Printf.sprintf "$(b,%s) [$(i,%s)]" cmd key

let set_usage ?raw () =
  let cmd = "dune-release config set" in
  let key = "KEY" in
  let value = "VALUE" in
  match raw with
  | Some () -> Printf.sprintf "%s %s %s" cmd key value
  | None -> Printf.sprintf "$(b,%s) $(i,%s) $(i,%s)" cmd key value

let invalid_usage () =
  Rresult.R.error_msgf
    "Invalid dune-release config invocation. Usage:\n%s\n%s\n%s"
    (default_usage ~raw:() ()) (show_usage ~raw:() ()) (set_usage ~raw:() ())

let run action key_opt value_opt =
  let res =
    match (action, key_opt, value_opt) with
    | "show", key, None -> show key
    | "set", Some key, Some value -> set key value
    | _ -> invalid_usage ()
  in
  match res with
  | Ok () -> 0
  | Error (`Msg s) ->
      App_log.unhappy (fun l -> l "%s" s);
      1

let man =
  let open Cmdliner in
  [
    `S Manpage.s_synopsis;
    `P (default_usage ());
    `P (show_usage ());
    `P (set_usage ());
    `S "GLOBAL CONFIGURATION FIELDS";
    `P
      "Here are the existing fields of dune-release's global config file. Only \
       those values should be used as $(i,KEY):";
    `P
      "$(b,user): The Github username of the opam-repository fork. Used to \
       open the final PR to opam-repository.";
    `P
      "$(b,remote): The URL to your remote Github opam-repository fork. Used \
       to open the final PR to opam-repository.";
    `P
      "$(b,local): The path to your local clone of opam-repository. Used to \
       open the final PR to opam-repository.";
    `P
      "$(b,keep-v): Whether or not the 'v' prefix in git tags should make it \
       to the final version number.";
    `P
      "$(b,auto-open): Whether dune-release should open your browser to the \
       newly created opam-repository PR or not.";
  ]

let info =
  let doc = "Displays or update dune-release global configuration" in
  Cmdliner.Term.info ~doc ~man "config"

let action =
  let docv = "ACTION" in
  let doc =
    "The action to perform, either $(b,show) the config or $(b,set) a config \
     field"
  in
  Cmdliner.Arg.(value & pos 0 string "show" & info ~doc ~docv [])

let key =
  let docv = "KEY" in
  let doc =
    "The configuration field to set or print. For $(b,show), if no key is \
     provided, the entire config will be printed."
  in
  Cmdliner.Arg.(value & pos 1 (some string) None & info ~doc ~docv [])

let value =
  let docv = "VALUE" in
  let doc = "The new field value" in
  Cmdliner.Arg.(value & pos 2 (some string) None & info ~doc ~docv [])

let term = Cmdliner.Term.(pure run $ action $ key $ value)

let cmd = (term, info)
