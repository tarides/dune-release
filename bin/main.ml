open Cmdliner

let cmd =
  Cmd.group ~default:Show.term (Cmd.info "caretaker")
    [ Show.cmd; Lint.cmd; Sync.cmd; Fetch.cmd ]

let () =
  let () = Printexc.record_backtrace true in
  match Cmd.eval ~catch:false cmd with
  | i -> exit i
  | exception Invalid_argument s ->
      Logs.err (fun m -> m "%s" s);
      exit Cmd.Exit.cli_error
  | exception Failure s ->
      Logs.err (fun m -> m "%s" s);
      exit 1
  | exception e ->
      Printexc.print_backtrace stderr;
      Logs.err (fun m -> m "%a" Fmt.exn e);
      exit Cmd.Exit.some_error
