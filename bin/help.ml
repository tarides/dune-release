(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

let dune_release_manual = "dune-release manual"
let version = "%%VERSION%%"

(* Help manuals *)

open Cmdliner

let see_also ~cmds =
  let cmds =
    Astring.String.concat ~sep:"(1), " ("dune-release" :: cmds) ^ "(1)"
  in
  [ `S Manpage.s_see_also; `P cmds ]

let release =
  ( ("DUNE-RELEASE", 7, "", version, dune_release_manual),
    [
      `S Manpage.s_name;
      `P "dune-release - How to release a (dune) package";
      `S Manpage.s_description;
      `P
        "The basic release script is the following. Each step is\n\
        \        refined and explained with more details below.";
      `Pre
        "dune-release tag           # Tag the distribution with a version\n\
         dune-release distrib       # Create the distribution archive\n\
         dune-release publish       # Publish it on the WWW with its \
         documentation\n\
         dune-release opam pkg      # Create an opam package\n\
         dune-release opam submit   # Submit it to OCaml's opam repository";
      `P
        "The last four steps can be performed via a single invocation\n\
        \        to dune-release(1).";
      `S "BASIC CHECKS";
      `P
        "Basic checks are performed on the distribution archive when it is\n\
        \        created, but save time by catching errors early. Hence test \
         that\n\
        \        your source repository lints and that it builds in the \
         current build\n\
        \        environment and that the package tests pass.";
      `Pre "dune-release check";
      `S "WRITE THE RELEASE NOTES";
      `P
        "Carefully write the release notes in the package's change log, these\n\
        \        are essential time savers for users of the package.";
      `S "VCS TAG THE RELEASE";
      `P
        "Here again dune-release provides a magic-less command that will simply\n\
        \        extract the latest version tag from the package's change log\n\
        \        and tag the VCS HEAD commit with it:";
      `Pre "dune-release tag";
      `P "This will only work if the change log follows a certain format.";
      `P
        "If you do not want to rely on dune-release's broken extraction \
         algorithms\n\
        \        just specify it on the command line:";
      `Pre "dune-release tag v1.0.1";
      `P
        "And if you really think dune-release does a bad job at this, simply\n\
        \        use your VCS directly to tag a release.";
      `S "CREATE THE DISTRIBUTION ARCHIVE AND PUBLISH IT";
      `P
        "Now that the release is tagged in your VCS, generate a distribution\n\
        \        archive for it in the build directory with:";
      `Pre "dune-release distrib";
      `P
        "This uses the source tree of the HEAD commit for creating a\n\
        \        distribution in the build directory. The distribution version\n\
        \        string is the VCS tag description (e.g.  git-describe(1)) of\n\
        \        the HEAD commit. Alternatively it can be specified on the \
         command\n\
        \        line.";
      `P
        "If everything went well you can now publish the distribution and\n\
        \        its documentation to Github.";
      `Pre "dune-release publish";
      `P
        "The distribution is now public. It may already have been picked up by \
         other systems hence do not try to alter the archive and republish it \
         with a different content after that point. It is instead recommended \
         to make a new release with a new version number.";
      `S "SUBMIT TO OCAML'S OPAM REPOSITORY";
      `P
        "The following steps still need the distribution archive created in\n\
        \        the preceding step to be in the build directory. If that's no\n\
        \        longer the case but nothing moved in your VCS, you can simply\n\
        \        invoke $(b,dune-release distrib), it should produce a \
         bit-wise identical\n\
        \        archive. If the VCS moved checkout the distribution commit to\n\
        \        regenerate the archive or provide, in the subsequent commands,\n\
        \        the archive manually via the $(b,--dist-file) option, see\n\
        \        dune-release-opam(1) for details.";
      `P
        "To add the package to OCaml's opam repository, start by creating an\n\
        \        opam package description in the build directory with:";
      `Pre "dune-release opam pkg";
      `P "then simply submit it to the opam repository with:";
      `Pre "dune-release opam submit";
      `P
        "The latter does nothing more than invoking opam-publish-submit(1) on\n\
        \        the package description generated earlier.";
      `P "Congratulations. You are done. Ditch your computer.";
      `S "TROUBLESHOOTING";
      `P "Here are a few troubleshooting scenarios and possible resolution.";
      `I
        ( "Before publishing",
          "Anything that happens before the $(b,dune-release publish) step,\n\
          \         like a failing $(b,dune-release distrib), is easy to \
           resolve. Delete the\n\
          \         version tag of your VCS, a $(b,dune-release tag -d) will \
           do, add\n\
          \         some commits, adjust your release notes and start over." );
      `I
        ( "opam submission build failure",
          "If the build failure is due to a missing constraint, follow the\n\
          \         instruction of the next item to correct the opam file. If \
           the failure\n\
          \         is due to a defect in the distribution archive, call it a \
           day and\n\
          \         start over with a patch version release that corrects the \
           problem.\n\
          \         Do not try to reuse the version string of the failed \
           release, other\n\
          \         systems may already have picked up the broken archive." );
      `I
        ( "opam repository maintainer and robot complaints",
          "These pesky but loved maintainers and robots... If they\n\
          \         complain about certain aspects of your opam submission, \
           you can either\n\
          \         try to correct it manually from the opam package \
           description found\n\
          \         in the build directory and reinvoke $(b,dune-release opam \
           submit) or edit\n\
          \         the opam file of the source repository and regenerate the \
           opam Package\n\
          \         description with $(b,dune-release opam pkg) and the \
           $(b,--pkg-opam)\n\
          \         option. Note that if the VCS moved meanwhile you may have \
           to use\n\
          \         the various command line options of dune-release-opam(1) \
           to make sure\n\
          \         you point to the right package version and distribution \
           archive.\n\
          \         In either case you should be aware that there will be a \
           mismatch\n\
          \         between the opam file in the distribution archive and the \
           one\n\
          \         you submitted to the opam repository. If this happens to \
           be a\n\
          \         problem, start over with a new patch version release." );
      `Blocks (see_also ~cmds:[]);
    ] )

let troubleshoot =
  ( ("DUNE-RELEASE-TROUBLESHOOT", 7, "", version, dune_release_manual),
    [
      `S Manpage.s_name;
      `P "dune-release-troubleshoot - A few troubleshooting tips";
      `S Manpage.s_description;
      `P
        "If you get into trouble try the following to get a better undersanding\n\
        \        of what is happening.";
      `S "ASK FOR MORE LOGGING";
      `P
        "Invoke $(b,dune-release) with $(b,-v), $(b,-v -v), $(b,--dry-run)\n\
        \        or use the\n\
        \        DUNE_RELEASE_VERBOSITY environment variable; see the \
         $(b,--verbosity)\n\
        \        option.";
      `P
        "Messages coming from the $(b,dune-release) tool are prefixed\n\
        \        by 'dune-release:' while those coming from the package \
         description are\n\
        \        prefixed by its base name, usually 'pkg.ml:'.";
      `S "DEBUG DEV PACKAGE INSTALLS";
      `P
        "If you need more information about what happens when dev packages\n\
        \         are installed (VCS pins or VCS packages) in opam, for \
         example the\n\
        \         actual watermark values, invoke opam as follows:";
      `P "DUNE_RELEASE_VERBOSITY=debug opam upgrade mypkg -v";
      `S "RELEASE PROCESS TROUBLES";
      `P "See the TROUBLESHOOTING section of dune-release(7).";
      `Blocks (see_also ~cmds:[]);
    ] )

let files =
  ( ("DUNE-RELEASE-FILES", 7, "", version, dune_release_manual),
    [
      `S Manpage.s_name;
      `P "dune-release-files - Format of the configuration files";
      `S Manpage.s_description;
      `S "LOCATION";
      `P
        "Configuration files are stored globally under\n\
        \        $(i,~/.config/dune/) directory:";
      `I ("$(b,release.yml)", "GitHub and Git parameters.");
      `I
        ( "$(b,github.token)",
          "the GitHub token used for doing GitHub API calls." );
      `S "RELEASE.YML";
      `P "$(i,~/.config/dune/release.yml) might contain the following entries:";
      `I
        ( "$(b,user)",
          "GitHub username of the current user.\n\
          \         By default it is guessed from the $(i,dev-repo)\n\
          \         field of the current opam project. Should be the ID used to\n\
          \         generate $(i,github.token)." );
      `I
        ( "$(b,remote)",
          "Location of a clone of opam repository, where the current user\n\
          \         has push access.\n\
          \         By default it is \
           https://github.com/$(b,user)/opam-repository." );
      `I
        ( "$(b,local)",
          "The local clone of $(b,remote). By default it is\n\
          \        $(i,~/git/opam-repository)." );
      `S "GITHUB.TOKEN";
      `P
        "$(b,~/.config/dune/github.token) contains a token generated via\n\
        \        GitHub web UI, by the user who ID is set in $(i,release.yml).\n\
        \        To create a new token, visit \
         https://github.com/settings/tokens and\n\
        \        click on $(b,Generate New Token). Pick a useful Token \
         description\n\
        \        (for instance \"dune-release\") and select only the \
         $(i,public_repo) scope.\n\
        \        $(b,dune-release) will save the token for you and give the \
         saved file the\n\
        \        correct permissions.";
      `Blocks (see_also ~cmds:[]);
    ] )

(* Help command *)

let pages =
  [ ("release", release); ("troubleshoot", troubleshoot); ("files", files) ]

(* Command line interface *)

open Cmdliner

let topic =
  let doc = "The topic to get help on, `topics' lists the topic." in
  Arg.(value & pos 0 (some string) None & info [] ~docv:"TOPIC" ~doc)

let doc = "Show help about dune-release"
let exits = Cli.exits
let man_xrefs = [ `Main ]

let man =
  [
    `S Manpage.s_description;
    `P "The $(tname) command shows help about $(mname).";
    `P "Use `topics' as $(i,TOPIC) to get a list of topics.";
  ]

let term =
  Term.(
    ret
      (let open Syntax in
       let+ man_format = Arg.man_format
       and+ topic = topic
       and+ commands = Term.choice_names in
       match topic with
       | None -> `Help (man_format, None)
       | Some topic -> (
           let topics = ("topics" :: commands) @ List.map fst pages in
           let topics = List.sort compare topics in
           let conv, _ = Arg.enum (List.rev_map (fun s -> (s, s)) topics) in
           match conv topic with
           | `Error e -> `Error (false, e)
           | `Ok t when List.mem t commands -> `Help (man_format, Some t)
           | `Ok t when t = "topics" ->
               Fmt.pr "@[<v>%a@]@." Fmt.(list string) topics;
               `Ok 0
           | `Ok t ->
               let man =
                 try List.assoc t pages with Not_found -> assert false
               in
               Fmt.pr "%a" (Manpage.print man_format) man;
               `Ok 0)))

let info = Cmd.info "help" ~doc ~exits ~man ~man_xrefs
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
