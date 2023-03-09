(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup
open Dune_release

let print_latest_change_log_entry () =
  let pkg = Pkg.v ~dry_run:true () in
  Pkg.change_log pkg >>= Text.change_log_file_last_entry
  >>| (fun (version, (title, body)) ->
        Fmt.pr "Tag: %a\nTitle: %s\nBody:\n%s\n" Version.Changelog.pp version
          title body;
        0)
  |> Cli.handle_error

open Cmdliner

let doc = "Print out the latest change log entry"

let man =
  [
    `S Manpage.s_description;
    `P "Parses the change log and prints the latest entry to stdout";
  ]

let term = Term.(const print_latest_change_log_entry $ const ())
let info = Cmd.info "change-log" ~doc ~man
let cmd = Cmd.v info term

(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli

   Permission to use, copy, modify, and/or distribute this software for any
   purpose with or without fee is hereby granted, provided that the above
   copyright notice and this permission notice appear in all copies.

   THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
   WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
   MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
   ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
   WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
   ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
   OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
  ---------------------------------------------------------------------------*)
