open Cmdliner
module Version = Dune_release.Version
module Vcs = Dune_release.Vcs

let version =
  Arg.conv ~docv:"An OPAM compatible version string"
    ((fun s -> Ok (Version.from_string s)), Version.pp)

let tag =
  Arg.conv ~docv:"A tag for VCS"
    ((fun s -> Ok (Vcs.Tag.from_string s)), Vcs.Tag.pp)
