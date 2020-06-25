open Bos_setup

type t = { url : string; args : string list }

type auth = { user : string; token : string }

let escape_for_json s =
  let len = String.length s in
  let max = len - 1 in
  let rec escaped_len i l =
    if i > max then l
    else
      match s.[i] with
      | '\\' | '\"' | '\n' | '\r' | '\t' -> escaped_len (i + 1) (l + 2)
      | _ -> escaped_len (i + 1) (l + 1)
  in
  let escaped_len = escaped_len 0 0 in
  if escaped_len = len then s
  else
    let b = Bytes.create escaped_len in
    let rec loop i k =
      if i > max then Bytes.unsafe_to_string b
      else
        match s.[i] with
        | ('\\' | '\"' | '\n' | '\r' | '\t') as c ->
            Bytes.set b k '\\';
            let c =
              match c with
              | '\\' -> '\\'
              | '\"' -> '\"'
              | '\n' -> 'n'
              | '\r' -> 'r'
              | '\t' -> 't'
              | _ -> assert false
            in
            Bytes.set b (k + 1) c;
            loop (i + 1) (k + 2)
        | c ->
            Bytes.set b k c;
            loop (i + 1) (k + 1)
    in
    loop 0 0

module Options = struct
  (* If the server reports that the requested page has moved to a different
     location, this option will make curl redo the request on the new place. *)
  let location args = "--location" :: args

  (* Specify the user name and password to use for server authentication. *)
  let user { user; token } args = "--user" :: strf "%s:%s" user token :: args

  (* Silent or quiet mode. Don't show progress meter or error messages. Makes
     Curl mute. It will still output the data you ask for, potentially even to
     the terminal/stdout unless you redirect it. *)
  let silent args = "--silent" :: args

  (* When used with -s, --silent, it makes curl show an error message if it
     fails. *)
  let show_error args = "--show-error" :: args

  (* Specify a text file to read curl arguments from. The command line
     arguments found in the text file will be used as if they were provided on
     the command line.
     Specify the filename to -K, --config as '-' to make curl read the file
     from stdin. *)
  let config file args = "--config" :: file :: args

  (* Write the received protocol headers to the specified file. *)
  let dump_header file args = "--dump-header" :: file :: args

  (* Sends the specified data in a POST request to the HTTP server. If the data
     starts with the letter @, the rest should be a filename. *)
  let data data args = "--data" :: data :: args

  (* This posts data exactly as specified with no extra processing whatsoever.
     If the data starts with the letter @, the rest should be a filename. *)
  let data_binary data args = "--data-binary" :: data :: args

  (* Extra header to include in the request when sending HTTP to a server. *)
  let header header args = "--header" :: header :: args
end

let create_release ~version ~msg ~user ~repo =
  let json =
    strf "{ \"tag_name\" : \"%s\", \"body\" : \"%s\" }"
      (escape_for_json version) (escape_for_json msg)
  in
  let url = strf "https://api.github.com/repos/%s/%s/releases" user repo in
  let args =
    let open Options in
    location @@ silent @@ show_error @@ config "-" @@ dump_header "-"
    @@ data json @@ []
  in
  { url; args }

let upload_archive ~archive ~user ~repo ~release_id =
  let url =
    strf "https://uploads.github.com/repos/%s/%s/releases/%d/assets?name=%s"
      user repo release_id (Fpath.filename archive)
  in
  let args =
    let open Options in
    location @@ silent @@ show_error @@ config "-" @@ dump_header "-"
    @@ header "Content-Type:application/x-tar"
    @@ data_binary (strf "@@%s" (Fpath.to_string archive))
    @@ []
  in
  { url; args }

let open_pr ~title ~user ~branch ~body ~opam_repo =
  let base, repo = opam_repo in
  let url = strf "https://api.github.com/repos/%s/%s/pulls" base repo in
  let json =
    strf {|{"title": %S,"base": "master", "body": %S, "head": "%s:%s"}|} title
      body user branch
  in
  let args =
    let open Options in
    silent @@ show_error @@ config "-" @@ dump_header "-" @@ data json @@ []
  in
  { url; args }

let with_auth ~auth { url; args } = { url; args = Options.user auth args }
