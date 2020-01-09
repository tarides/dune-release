open Bos_setup

module Sbytes = struct
  type t = Bytes.t

  let make size char =
    try R.ok (Bytes.make size char) with Invalid_argument e -> R.error_msg e

  let blit_string src srcoff dst dstoff len =
    try R.ok (Bytes.blit_string src srcoff dst dstoff len)
    with Invalid_argument e -> R.error_msg e
end

module Path = struct
  let is_backup_file str =
    let len = String.length str in
    len > 0
    &&
    let first = str.[0] in
    let last = str.[len - 1] in
    Char.equal last '~' || (Char.equal first '#' && Char.equal last '#')

  let find_files ~names_wo_ext files =
    let open Fpath in
    List.filter
      (fun file ->
        if is_backup_file (filename file) then false
        else
          let normalized = to_string (normalize (rem_ext file)) in
          List.exists
            (String.equal (String.Ascii.lowercase normalized))
            names_wo_ext)
      files
end

module Unix = struct
  let maybe_echo_input echo_input f x =
    if echo_input then f x
    else
      let open Unix in
      let term_io = tcgetattr stdin in
      tcsetattr stdin TCSANOW { term_io with c_echo = false };
      let input = f x in
      tcsetattr stdin TCSANOW term_io;
      input

  let read_line ?(echo_input = true) () =
    maybe_echo_input echo_input read_line ()
end
