open Bos_setup

let create_release ~version ~msg ~user ~repo =
  let data =
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
    in
    strf "{ \"tag_name\" : \"%s\", \"body\" : \"%s\" }"
      (escape_for_json version) (escape_for_json msg)
  in
  let uri = strf "https://api.github.com/repos/%s/%s/releases" user repo in
  [ "-D"; "-"; "--data"; data; uri ]

let upload_archive ~archive ~user ~repo ~release_id =
  [
    "-H";
    "Content-Type:application/x-tar";
    "--data-binary";
    strf "@@%s" (Fpath.to_string archive);
    strf "https://uploads.github.com/repos/%s/%s/releases/%d/assets?name=%s"
      user repo release_id (Fpath.filename archive);
  ]
