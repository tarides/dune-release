(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

(** Text processing helpers. *)

open Bos_setup

(** {1 Marked-up text files}

    {b Warning.} Some of the following functions are not serious and can
    break on certain valid inputs in all sorts of fashion. To understand
    breakage bear in mind that they operate line-wise. *)

type flavour = [ `Markdown | `Asciidoc ]
(** The type for text document formats. *)

val flavour_of_fpath : Fpath.t -> flavour option
(** [flavour_of_fpath p] determines a flavour according to the
    extension of [p] as follows:
    {ul
    {- [Some `Markdown] for [.md]}
    {- [Some `Asciidoc] for [.asciidoc] or [.adoc]}
    {- [None] otherwise}} *)

val head : ?flavour:flavour -> string -> (string * string) option
(** [head ~flavour text] extracts the {e head} of the document [text] of
    flavour [flavour] (defaults to [`Markdown]).

    The head is defined as follows:
    {ul
    {- Anything before the first header is discarded.}
    {- The first header is kept in the first component}
    {- Everything that follows until the next header of the same or greater
       level is kept discarding trailing blank lines.}} *)

val header_title : ?flavour:flavour -> string -> string
(** [header_title ~flavour text] extract the title of a header [text]
    of flavour [flavour] (defaults to [`Markdown]). *)

(** {1 Toy change log parsing} *)

val change_log_last_entry :
  ?flavour:flavour -> string -> (string * (string * string)) option
(** [change_log_last_version ~flavour text] tries to parse the last
    change log entry of [text] (i.e. the {!head} of [text]) into
    [Some (version, (header, text))], where [(header,text)] is the
    result of {!head} and [version] a version number extracted from
    [header] (see [dune-release-log(2)] for details). *)

val change_log_file_last_entry :
  Fpath.t -> ((string * (string * string)), R.msg) result
(** [change_log_file_last_entry file] tries to parse the last
    change log entry of the file [file] using {!flavour_of_fpath} and
    and {!change_log_last_entry}. *)

(** {1 Toy URI parsing} *)

val split_uri : ?rel:bool -> string -> (string * string * string) option
(** [split_uri uri] splits [uri] into a triple [(scheme, host, path)]. If
    [rel] is [true] (defaults to [false]), a leading ["/"] in [path] is
    removed. *)

(** {1 Edit and page text} *)

val edit_file : Fpath.t -> (int, R.msg) result
(** [edit_file f] invokes the tool mentioned in the [EDITOR]
    environment variable with [f] and returns the exit code of
    the program. *)

val find_pager : don't:bool -> (Cmd.t option, R.msg) result
(** [find ~no_pager] is an optional pager command. If [don't] is
    [true] returns [None]. Otherwise first consults the [PAGER] environment
    variable, then tries [less] or [more] in that order. If the [TERM]
    environment variable is ["dumb"] or undefined unconditionaly returns
    [None]. *)

(** Pretty printers. *)
module Pp : sig

  (** {1 Pretty printers} *)

  val name : string Fmt.t
  (** [name] formats a package name. *)

  val version : string Fmt.t
  (** [version] formats a package version. *)

  val commit : string Fmt.t
  (** [commit] formats a commit-ish. *)

  val dirty : unit Fmt.t
  (** [dirty] formats a "dirty" string. *)

  val path : Fpath.t Fmt.t
  (** [path] formats a bold path *)

  val status : [`Ok | `Fail] Fmt.t
  (** [status] formats a result status. *)
end

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
