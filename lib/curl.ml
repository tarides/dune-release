open Bos_setup

type t = { url : string; args : Curl_option.t list }

let create_release ~version ~tag ~msg ~user ~repo =
  let json : string =
    Yojson.Basic.to_string
      (`Assoc
        [
          ("tag_name", `String tag);
          ("name", `String version);
          ("body", `String msg);
        ])
  in
  let url = strf "https://api.github.com/repos/%s/%s/releases" user repo in
  let args =
    let open Curl_option in
    [
      Location;
      Silent;
      Show_error;
      Config `Stdin;
      Dump_header `Ignore;
      Data (`Data json);
    ]
  in
  { url; args }

let get_release ~version ~user ~repo =
  let url =
    strf "https://api.github.com/repos/%s/%s/releases/tags/%s" user repo version
  in
  let args =
    let open Curl_option in
    [ Location; Silent; Show_error; Config `Stdin; Dump_header `Ignore ]
  in
  { url; args }

let upload_archive ~archive ~user ~repo ~release_id =
  let url =
    strf "https://uploads.github.com/repos/%s/%s/releases/%d/assets?name=%s"
      user repo release_id (Fpath.filename archive)
  in
  let args =
    let open Curl_option in
    [
      Location;
      Silent;
      Show_error;
      Config `Stdin;
      Dump_header `Ignore;
      Header "Content-Type:application/x-tar";
      Data_binary (`File (Fpath.to_string archive));
    ]
  in
  { url; args }

let open_pr ~title ~user ~branch ~body ~opam_repo =
  let base, repo = opam_repo in
  let url = strf "https://api.github.com/repos/%s/%s/pulls" base repo in
  let json =
    Yojson.Basic.to_string
      (`Assoc
        [
          ("title", `String title);
          ("base", `String "master");
          ("body", `String body);
          ("head", `String (strf "%s:%s" user branch));
        ])
  in
  let args =
    let open Curl_option in
    [
      Silent; Show_error; Config `Stdin; Dump_header `Ignore; Data (`Data json);
    ]
  in
  { url; args }

let with_auth ~auth { url; args } =
  { url; args = Curl_option.User auth :: args }
