(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup

type os = [ `Build_os | `Host_os ]

let os_tool_env name os =
  let pre = match os with `Build_os -> "BUILD_OS_" | `Host_os -> "HOST_OS_" in
  pre ^ String.Ascii.uppercase name

let os_bin_dir_env = function
| `Build_os -> "BUILD_OS_BIN"
| `Host_os -> "HOST_OS_XBIN"

let os_suff_env = function
| `Build_os -> "BUILD_OS_SUFF"
| `Host_os -> "HOST_OS_SUFF"

let ocamlfindable name = match name with
| "ocamlc" | "ocamlcp" | "ocamlmktop" | "ocamlopt" | "ocamldoc" | "ocamldep"
| "ocamlmklib" | "ocamlbrowser" as tool ->
    let toolchain = Cmd.empty in
    Some Cmd.(v "ocamlfind" %% toolchain % tool)
| _ -> None

let tool name os = match OS.Env.var (os_tool_env name os) with
| Some cmd -> Cmd.v cmd
| None ->
    match OS.Env.var (os_bin_dir_env os) with
    | Some path -> Cmd.v Fpath.(to_string @@ v path / name)
    | None ->
        match OS.Env.var (os_suff_env os) with
        | Some suff -> Cmd.v (name ^ suff)
        | None ->
            match ocamlfindable name with
            | Some cmd -> cmd
            | None -> Cmd.v name

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
