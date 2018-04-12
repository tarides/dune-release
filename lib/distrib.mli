(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

(** {1 Distribution description} *)

open Rresult

(** {1:distrib Distribution description} *)

type watermark = string * [ `String of string | `Version | `Version_num
                          | `Name | `Vcs of [`Commit_id]
                          | `Opam of Fpath.t option * string * string]
(** The type for watermarks. A watermark identifier, e.g. ["ID"] and its
    definition:
      {ul
      {- [`String s], [s] is the definition.}
      {- [`Name], is the name of package.}
      {- [`Version], is the version of the distribution.}
      {- [`Version_num], is the version of the distribution with a potential
         leading ['v'] or ['V'] dropped.}
      {- [`Vcs `Commit_id], is the commit identifier (hash) of the
         distribution. May be post-fixed by ["dirty"] in
         {{!Conf.build_context}dev package ([`Pin]) builds}.}
      {- [`Opam (file, field, sep)], is the values of the field
         [field] concatenated with separator [sep] of the opam file
         [file], expressed relative to the distribution root directory, if
         [file] is [None] this is the package's default opam file, see
         {!describe}. Not all fields are supported see the value of
         {!Topkg_care.Opam.File.field_names}.  {b Warning.} In
         {{!Conf.build_context}dev package ([`Pin]) builds}, [`Opam]
         watermarks are only substituted if the package [topkg-care] is
         installed.}}

      When a file is watermarked with an identifier ["ID"], any occurence of
      the sequence [%%ID%%] in its content is substituted by its definition. *)

type t
(** The type for describing distribution creation. *)

val v :
  ?watermarks:watermark list ->
  ?files_to_watermark:(unit -> (Fpath.t list, R.msg) result) ->
  ?massage:(unit -> (unit, R.msg) result) ->
  ?exclude_paths:(unit -> (Fpath.t list, R.msg) result) ->
  unit -> t
(** [distrib ~watermarks ~files_to_watermark ~massage
      ~exclude_paths ()] influences the distribution creation
      process performed by the [topkg] tool.
      See the {{!distdetails}full details about distribution creation}.

      In the following the {e distribution build directory} is a
      private clone of the package's source repository's [HEAD] when
      [topkg distrib] is invoked.
      {ul
      {- [watermarks] defines the source watermarks for the distribution,
         defaults to {!watermarks}.}
      {- [files_to_watermark] is invoked in the distribution build
         directory to determine the files to watermark, defaults
         to {!files_to_watermark}.}
      {- [massage] is invoked in the distribution build directory,
         after watermarking, but before archiving. It can be used to
         generate distribution time build artefacts. Defaults to {!massage}.}
      {- [exclude_paths ()] is invoked in the distribution build
         directory, after massaging, to determine the paths that are
         excluded from being added to the distribution archive. Defaults to
         {!exclude_paths}.}} *)

val default_watermarks : watermark list
(** [default_watermarks] is the default list of watermarks. It has the following
      elements:
      {ul
      {- [("NAME", `Name)]}
      {- [("VERSION", `Version)]}
      {- [("VERSION_NUM", `Version_num)]}
      {- [("VCS_COMMIT_ID", `Vcs [`Commit_id])]}
      {- [("PKG_MAINTAINER", `Opam (None, "maintainer", ", "))]}
      {- [("PKG_AUTHORS", `Opam (None, "authors", ", ")]}
      {- [("PKG_HOMEPAGE", `Opam (None, "homepage", " ")]}
      {- [("PKG_ISSUES", `Opam (None, "bug-reports", " ")]}
      {- [("PKG_DOC", `Opam (None, "doc", " "))]}
      {- [("PKG_LICENSE", `Opam (None, "license", ", ")]}
      {- [("PKG_REPO", `Opam (None, "dev-repo", " "))]}}
      Prepending to the list overrides default definitions. *)

val default_files_to_watermark : unit -> (Fpath.t list, R.msg) result
(** [default_files_to_watermark ()] is the default list of files to
    watermark.  It is invoked in the distribution build directory and
    gets the set of {{!Vcs.tracked_files}tracked files} of this
    directory from which it removes the files that end with [.flv],
    [.gif], [.ico], [.jpeg], [.jpg], [.mov], [.mp3], [.mp4], [.otf],
    [.pdf], [.png], [.ttf], [.woff]. *)

val default_massage : unit -> (unit, R.msg) result
(** [default_massage] is the default distribution massaging
    function. It is invoked in the distribution build directory and
    does nothing. *)

val default_exclude_paths : unit -> (Fpath.t list, R.msg) result
(** [default_exclude_paths ()] is the default list of paths to exclude
    from the distribution archive. It is invoked in the distribution build
    directory and returns the following static set of files.

    {[
      fun () -> Ok [".git"; ".gitignore"; ".gitattributes"; ".hg"; ".hgignore";
                    "build"; "Makefile"; "_build"]]} *)

val watermarks : t -> watermark list
val files_to_watermark : t -> (unit -> (Fpath.t list, R.msg) result)
val massage : t -> (unit -> (unit, R.msg) result)
val exclude_paths : t -> (unit -> (Fpath.t list, R.msg) result)

val define_watermarks :
  name:string -> version:string -> opam:Fpath.t ->
  watermark list -> (string * string) list

val watermark_files :
  (string * string) list -> Fpath.t list -> (unit, R.msg) result

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
