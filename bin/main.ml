open Cmdliner

let cmd =
  Cmd.group ~default:Show.term (Cmd.info "caretaker")
    [ Show.cmd; Lint.cmd; Sync.cmd; Fetch.cmd ]

let () =
  let () = Printexc.record_backtrace true in
  match Cmd.eval ~catch:false cmd with
  | i -> exit i
  | exception Invalid_argument s ->
      Fmt.epr "\n%a %s\n%!" Fmt.(styled `Red string) "[ERROR]" s;
      exit Cmd.Exit.cli_error
  | exception e ->
      Printexc.print_backtrace stderr;
      Fmt.epr "\n%a\n%!" Fmt.exn e;
      exit Cmd.Exit.some_error
