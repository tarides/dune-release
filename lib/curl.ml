open Bos_setup

type t = { url : string; args : string list }

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

let create_release ~version ~msg ~user ~repo =
  let data =
    strf "{ \"tag_name\" : \"%s\", \"body\" : \"%s\" }"
      (escape_for_json version) (escape_for_json msg)
  in
  let url = strf "https://api.github.com/repos/%s/%s/releases" user repo in
  let args = [ "-L"; "-s"; "-S"; "-K"; "-"; "-D"; "-"; "--data"; data ] in
  { url; args }

let upload_archive ~archive ~user ~repo ~release_id =
  let url =
    strf "https://uploads.github.com/repos/%s/%s/releases/%d/assets?name=%s"
      user repo release_id (Fpath.filename archive)
  in
  let args =
    [
      "-L";
      "-s";
      "-S";
      "-K";
      "-";
      "-H";
      "Content-Type:application/x-tar";
      "--data-binary";
      strf "@@%s" (Fpath.to_string archive);
    ]
  in
  { url; args }

let open_pr ~title ~user ~branch ~body ~opam_repo =
  let base, repo = opam_repo in
  let url = strf "https://api.github.com/repos/%s/%s/pulls" base repo in
  let data =
    strf {|{"title": %S,"base": "master", "body": %S, "head": "%s:%s"}|} title
      body user branch
  in
  let args = [ "-s"; "-S"; "-K"; "-"; "-D"; "-"; "--data"; data ] in
  { url; args }

let with_auth ~auth { url; args } = { url; args = "-u" :: auth :: args }
