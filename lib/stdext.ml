open Bos_setup

module Sbytes = struct
  type t = Bytes.t

  let make size char =
    try R.ok (Bytes.make size char) with Invalid_argument e -> R.error_msg e

  let blit_string src srcoff dst dstoff len =
    try R.ok (Bytes.blit_string src srcoff dst dstoff len)
    with Invalid_argument e -> R.error_msg e
end
