(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Cmdliner

let cmds =
  [Status.cmd; Log.cmd; Tag.cmd; Distrib.cmd;
   Publish.cmd; Opam.cmd; Help.cmd;
   Bistro.cmd; Lint.cmd; ]

(* Command line interface *)

let doc = "Release dune packages to opam"
let sdocs = Manpage.s_common_options
let exits = Cli.exits
let man =
  [ `S Manpage.s_description;
    `P "$(mname) releases dune packages to opam.";
    `P "Without arguments, $(mname) acts like $(b,dune-release bistro):
        refer to $(b,dune-release help bistro) for help about the
        default behavior.";
    `P "Use '$(mname) help release' for help to release a package.";
    `Noblank;
    `P "Use '$(mname) help troubleshoot' for a few troubleshooting tips.";
    `Noblank;
    `P "Use '$(mname) help $(i,COMMAND)' for help about $(i,COMMAND).";
    `S Manpage.s_bugs;
    `P "Report them, see $(i,%%PKG_HOMEPAGE%%) for contact information.";
    `S Manpage.s_authors;
    `P "Daniel C. Buenzli, $(i,http://erratique.ch)"; ]

let main =
  fst Bistro.cmd,
  Term.info "dune-release" ~version:"%%VERSION%%" ~doc ~sdocs ~exits ~man

let main () =
  Term.(exit_status @@ eval_choice main cmds)

let () = main ()

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
