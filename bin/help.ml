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
    (Astring.String.concat ~sep:"(1), " ("dune-release" :: cmds)) ^ "(1)"
  in
  [ `S Manpage.s_see_also; `P cmds ]

let release =
  ("DUNE-RELEASE", 7, "", version, dune_release_manual),
  [ `S Manpage.s_name;
    `P "dune-release - How to release a (dune) package";
    `S Manpage.s_description;
    `P "The basic release script is the following. Each step is
        refined and explained with more details below.";
    `Pre "\
dune-release status        # Review the changes since last version
dune-release log edit      # Write the release notes
dune-release log commit    # Commit the release notes
dune-release tag           # Tag the distribution with a version
dune-release distrib       # Create the distribution archive
dune-release publish       # Publish it on the WWW with its documentation
dune-release opam pkg      # Create an opam package
dune-release opam submit   # Submit it to OCaml's opam repository";
    `P "The last four steps can be performed via a single invocation
        to dune-release-bistro(1).";
    `S "BASIC CHECKS";
    `P "Basic checks are performed on the distribution archive when it is
        created, but save time by catching errors early. Hence test that
        your source repository lints and that it builds in the current build
        environment and that the package tests pass.";
    `Pre "\
dune-release lint
dune build # Check out the generated opam install file too
dune runtest";
    `S "WRITE THE RELEASE NOTES";
    `P "Carefully write the release notes in the package's change log, these
        are essential time savers for users of the package. It may help to
        consult the list of changes that were committed since the last VCS
        version tag with:";
    `Pre "dune-release status";
    `P "You can then write the release notes and commit them to the VCS with:";
    `Pre "\
dune-release log edit
dune-release log commit";
    `P "The next step is simplified if the change log follows a certain
        format, see dune-release-log(1) for details.";
    `P "The last two commands mentioned perform no magic, it is entirely up
        to you to use them or not. The first one simply opens the change log
        of the package in your \\$EDITOR and the second one commits it to
        your VCS with a dull, canned, commit message.";
    `S "VCS TAG THE RELEASE";
    `P "Here again dune-release provides a magic-less command that will simply
        extract the latest version tag from the package's change log
        and tag the VCS HEAD commit with it:";
    `Pre "dune-release tag";
    `P "This will only work if the change log follows a certain format,
        see tokpg-log(1) for details. You can check the extracted tag is
        the one you wish before with:";
    `Pre "dune-release log -t";
    `P "If you do not want to rely on dune-release's broken extraction algorithms
        just specify it on the command line:";
    `Pre "dune-release tag v1.0.1";
    `P "And if you really think dune-release does a bad job at this, simply
        use your VCS directly to tag a release.";
    `S "CREATE THE DISTRIBUTION ARCHIVE AND PUBLISH IT";
    `P "Now that the release is tagged in your VCS, generate a distribution
        archive for it in the build directory with:";
    `Pre "dune-release distrib";
    `P "This uses the source tree of the HEAD commit for creating a
        distribution in the build directory. The distribution version
        string is the VCS tag description (e.g.  git-describe(1)) of
        the HEAD commit. Alternatively it can be specified on the command
        line.";
    `P "If everything went well you can now publish the distribution and
        its documentation on the WWW.";
    `Pre "dune-release publish";
    `P "The distribution is now public. It may already have been picked up
        by other systems hence do not try to alter the archive and
        republish it with a different bit-stream after that point (if
        you are tempted to do this please consider taking a functional
        programming course). At worst 410 the archive from
        the WWW. But in most cases, if there is a problem with the
        archive, simply leave it there and publish a new one with an
        increased patch version number.";
    `S "SUBMIT TO OCAML'S OPAM REPOSITORY";
    `P "The following steps still need the distribution archive created in
        the preceeding step to be in the build directory. If that's no
        longer the case but nothing moved in your VCS, you can simply
        invoke $(b,dune-release distrib), it should produce a bit-wise identical
        archive. If the VCS moved checkout the distribution commit to
        regenerate the archive or provide, in the subsequent commands,
        the archive manually via the $(b,--dist-file) option, see
        dune-release-opam(1) for details.";
    `P "To add the package to OCaml's opam repository, start by creating an
        opam package description in the build directory with:";
    `Pre "dune-release opam pkg";
    `P "then simply submit it to the opam repository with:";
    `Pre "dune-release opam submit";
    `P "The latter does nothing more than invoking opam-publish-submit(1) on
        the package description generated earlier.";
    `P "Congratulations. You are done. Ditch your computer.";
    `S "TROUBLESHOOTING";
    `P "Here are a few troubleshooting scenarios and possible resolution.";
    `I ("Before publishing",
        "Anything that happens before the $(b,dune-release publish) step,
         like a failing $(b,dune-release distrib), is easy to resolve. Delete the
         version tag of your VCS, a $(b,dune-release tag -d) will do, add
         some commits, adjust your release notes and start over.");
    `I ("opam submission build failure",
        "If the build failure is due to a missing constraint, follow the
         instruction of the next item to correct the opam file. If the failure
         is due to a defect in the distribution archive, call it a day and
         start over with a patch version release that corrects the problem.
         Do not try to reuse the version string of the failed release, other
         systems may already have picked up the broken archive.");
    `I ("opam repository maintainer and robot complaints",
        "These pesky but loved maintainers and robots... If they
         complain about certain aspects of your opam submission, you can either
         try to correct it manually from the opam package description found
         in the build directory and reinvoke $(b,dune-release opam submit) or edit
         the opam file of the source repository and regenerate the opam Package
         description with $(b,dune-release opam pkg) and the $(b,--pkg-opam)
         option. Note that if the VCS moved meanwhile you may have to use
         the various command line options of dune-release-opam(1) to make sure
         you point to the right package version and distribution archive.
         In either case you should be aware that there will be a mismatch
         between the opam file in the distribution archive and the one
         you submitted to the opam repository. If this happens to be a
         problem, start over with a new patch version release.");
    `Blocks (see_also ~cmds:[]); ]

let delegate =
  ("DUNE-RELEASE-DELEGATE", 7, "", version, dune_release_manual),
  [ `S Manpage.s_name;
    `P "dune-release-delegate - The dune-release publish delegate";
    `S Manpage.s_description;
    `P "The delegate of a package is a program invoked by dune-release to perform
        actions that are difficult or not desirable to standardize within
        dune-release itself, namely:";
    `I ("$(b,dune-release publish)",
        "Publish distribution archives and derived artefacts.");
    `P "A sample delegate is provided at the end of this man page.";
    `S "DELEGATE LOOKUP PROCEDURE";
    `P "The delegate used by a package is defined by the first match in the
        following lookup procedure.";
    `I ("1. Command line", "Specified with the $(b,--delegate) option on
         the command line.");
    `I ("2. Environment variable.", "Specified in the DUNE_RELEASE_DELEGATE
         environment variable.");
    `I ("3. Homepage derived discovery.", "Consult the 'homepage' field of the
        package's opam file, extract the second-level domain of the URI as
        \\$NAME and uses the tool $(b,\\$NAME-dune-release-delegate) iff it exists
        in the executable search path. For example if the homepage is
        http://www.example.org/mypackage, an existing
        $(b,example-dune-release-delegate) tool will be used.");
    `I ("4. GitHub fallback.", "If the previous step yields
         $(b,github-dune-release-delegate) but that it doesn't exist in the
         executable search path.");
    `S "DELEGATE PROTOCOL";
    `P "The delegate is invoked by $(b,dune-release) with a request in order to
        finish its own execution. This means that the delegate takes over
        $(b,dune-release)'s standard channels and is in charge until the end of
        execution (except on errors, see below).";
    `P "The delegate always gets information as command line arguments with
        file paths arguments given as absolute paths. The first argument is
        always 'ipc' and is followed by a verbosity parameter:";
    `P "my-dune-release-delegate ipc $(i,VERB) $(i,ARG) ...";
    `P "$(i,VERB) will be either `quiet', `error', `warning', `info' or
        `debug' and the delegate must adjust its logging level appropriately.
        The remaining arguments are the request, see below for requests
        made by $(b,dune-release).";
    `P "The delegate must always exit with one of the following exit codes:";
    `I ("0", "The request is successful."); `Noblank;
    `I ("1", "The request is unsupported."); `Noblank;
    `I ("2", "The request errored.");
    `P "Exit 0 must be returned iff the request could be fulfilled according
        to its semantics.";
    `P "Exit 1 must be returned iff the request arguments cannot be
        understood or if the request is not implemented by the delegate.
        In this case the delegate must produce no output.";
    `P "Exit 2 must be returned iff the request could not be fulfilled
        according to its semantics. In this case it is the delegate's duty
        to provide good error messages for diagnosis on standard output";
    `P "In both non-zero exit codes, it is not the delegate's duty to
        try to save request data. In these cases $(b,dune-release) will take over
        again in order to prevent user input data loss. This
        occurs for example on issue creation, so that the issue
        description the user may have input interactively is not
        lost but \"saved\" to standard output.";
    `S "PUBLISH DELEGATION";
    `P "Publish delegation requests have the form:";
    `P "publish $(i,ACTION) $(i,ARG)...";
    `P "The following actions are currently defined.";
    `I ("publish distrib $(i,DISTRIB_URI) $(i,NAME) $(i,VERSION)
         $(i,MSG) $(i,ARCHIVE)",
        "Publish the distribution archive file $(i,ARCHIVE) for the package
         named $(i,NAME) at version $(i,VERSION) with publication
         message $(i,MSG). See dune-release API's documentation
         for information about the value of $(i,DISTRIB_URI).");
    `I ("publish doc $(i,DOC_URI) $(i,NAME) $(i,VERSION) $(i,MSG) $(i,DOCDIR)",
        "Publish the documentation directory $(i,DOCDIR) for the package
         named $(i,NAME) at version $(i,VERSION) with publication message
         $(i,MSG). $(i,DOC_URI) has the value of the doc field of the
         package's opam file.");
    `I ("publish alt $(i,DISTRIB_URI) $(i,KIND) $(i,NAME) $(i,VERSION)
         $(i,MSG) $(i,ARCHIVE)",
        "Alternative publication artefact named $(i,KIND). The semantics
         of the action is left to the delegate. The request arguments
         are the same as those of the distrib action.");
    `S "SAMPLE UNSUPPORTIVE DELEGATE";
    `P "This delegate script can be used as a blueprint. All requests
        are simply unsupported.";
`Pre "\
#!/usr/bin/env ocaml
#use \"topfind\"
#require \"bos.setup\"
open Bos_setup

let unsupported = Ok 1

let publish = function
| \"distrib\" :: uri :: name :: version :: msg :: archive :: _ ->
    unsupported
| \"doc\" :: uri :: name :: version :: msg :: docdir :: _ ->
    unsupported
| \"alt\" :: kind :: uri :: name :: version :: msg :: archive :: _ ->
    unsupported
| args ->
    unsupported

let request = function
| \"publish\" :: args -> publish args
| args -> unsupported

let main () =
  let doc = \"the unsupportive delegate\" in
  begin match OS.Arg.(parse ~doc ~pos:string ()) with
  | \"ipc\" :: verbosity :: req ->
      Logs.level_of_string verbosity
      >>= fun level -> Logs.set_level level; request req
  | \"ipc\" :: [] ->
      R.error_msg \"malformed delegate request, verbosity is missing\"
  | args ->
      R.error_msgf \"unknown arguments: %s\" (String.concat ~sep:\" \" args)
  end
  |> Logs.on_error_msg ~use:(fun () -> 2)

let () = exit (main ())
";
    `Blocks (see_also ~cmds:["dune-release-issue"; "dune-release-publish"]); ]

let troubleshoot =
  ("DUNE-RELEASE-TROUBLESHOOT", 7, "", version, dune_release_manual),
  [ `S Manpage.s_name;
    `P "dune-release-troubleshoot - A few troubleshooting tips";
    `S Manpage.s_description;
    `P "If you get into trouble try the following to get a better undersanding
        of what is happening.";
    `S "ASK FOR MORE LOGGING";
    `P "Invoke $(b,dune-release) with $(b,-v), $(b,-v -v), $(b,--dry-run)
        or use the
        DUNE_RELEASE_VERBOSITY environment variable; see the $(b,--verbosity)
        option.";
    `P "Messages comming from the $(b,dune-release) tool are prefixed
        by 'dune-release:' while those comming from the package description are
        prefixed by its base name, usually 'pkg.ml:'.";
    `S "DEBUG DEV PACKAGE INSTALLS";
    `P "If you need more information about what happens when dev packages
         are installed (VCS pins or VCS packages) in opam, for example the
         actual watermark values, invoke opam as follows:";
    `P "DUNE_RELEASE_VERBOSITY=debug opam upgrade mypkg -v";
    `S "RELEASE PROCESS TROUBLES";
    `P "See the TROUBLESHOOTING section of dune-release(7).";
    `Blocks (see_also ~cmds:[]) ]

let files =
  ("DUNE-RELEASE-FILES", 7, "", version, dune_release_manual),
  [ `S Manpage.s_name;
    `P "dune-release-files - Format of the configuration files";
    `S Manpage.s_description;
    `S "LOCATION";
    `P "Configuration files are stored globally under
        $(i,~/.config/dune/) directory:";
    `I ("$(b,release.yml)",
        "GitHub and Git parameters.");
    `I ("$(b,github.token)",
        "the GitHub token used for doing GitHub API calls.");
    `S "RELEASE.YML";
    `P "$(i,~/.config/dune/release.yml) might contain the following entries:";
    `I ("$(b,user)",
        "GitHub username of the current user.
         By default it is guessed from the $(i,dev-repo)
         field of the current opam project. Should be the ID used to
         generate $(i,github.token).");
    `I ("$(b,remote)",
        "Location of a clone of opam repository, where the current user
         has push access.
         By default it is https://github.com/$(b,user)/opam-repository.");
    `I ("$(b,local)",
        "The local clone of $(b,remote). By default it is
        $(i,~/git/opam-repository).");
    `S "GITHUB.TOKEN";
    `P "$(b,~/.config/dune/github.token) contains a token generated via
        GitHub web UI, by the user who ID is set in $(i,release.yml).
        To create a new token, visit https://github.com/settings/tokens and
        click on $(b,Generate New Token). Pick a useful Token description
        (for instance \"dune-release\") and select only the $(i,public_repo) scope.
        $(b,dune-release) will save the token for you and give the saved file the
        correct permissions.";
    `Blocks (see_also ~cmds:[]) ]

(* Help command *)

let pages =
  [ "release", release;
    "delegate", delegate;
    "troubleshoot", troubleshoot;
    "files", files]

let help man_format topic commands = match topic with
| None -> `Help (man_format, None)
| Some topic ->
    let topics = "topics" :: commands @ (List.map fst pages) in
    let topics = List.sort compare topics in
    let conv, _ = Cmdliner.Arg.enum (List.rev_map (fun s -> (s, s)) topics) in
    match conv topic with
    | `Error e -> `Error (false, e)
    | `Ok t when List.mem t commands -> `Help (man_format, Some t)
    | `Ok t when t = "topics" ->
        Fmt.pr "@[<v>%a@]@." Fmt.(list string) topics;
        `Ok 0
    | `Ok t ->
        let man = try List.assoc t pages with Not_found -> assert false in
        Fmt.pr "%a" (Cmdliner.Manpage.print man_format) man;
        `Ok 0

(* Command line interface *)

open Cmdliner

let topic =
  let doc = "The topic to get help on, `topics' lists the topic." in
  Arg.(value & pos 0 (some string) None & info [] ~docv:"TOPIC" ~doc)

let doc = "Show help about dune-release"
let exits = Cli.exits
let man_xrefs = [`Main]
let man =
  [ `S Manpage.s_description;
    `P "The $(tname) command shows help about $(mname).";
    `P "Use `topics' as $(i,TOPIC) to get a list of topics." ]

let cmd =
  Term.(ret (const help $ Term.man_format $ topic $ Term.choice_names)),
  Term.info "help" ~doc ~exits ~man ~man_xrefs

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
