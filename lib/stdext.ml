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

  let find_files ~name_wo_ext files =
    let open Fpath in
    List.filter
      (fun file ->
        if is_backup_file (filename file) then false
        else
          let normalized = to_string (normalize (rem_ext file)) in
          String.equal name_wo_ext (String.Ascii.lowercase normalized))
      files
end
