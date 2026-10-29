let header style c fmt () =
  Fmt.string fmt "[";
  Fmt.(styled style (const char c)) fmt ();
  Fmt.string fmt "]"

let app_log ?src pp_header f =
  Logs.app ?src (fun l ->
      f (fun ?header ?tags fmt -> l ?header ?tags ("%a " ^^ fmt) pp_header ()))

let status ?src f = app_log ?src (header `Yellow '-') f

(* On a terminal the answer is typed on the question's line, so the question
   does not end it. *)
let question ?(src = Logs.default) f =
  let pp_header = header `Magenta '?' in
  if Unix.isatty Unix.stdin then
    match Logs.Src.level src with
    | None -> ()
    | Some _ ->
        f (fun ?header:_ ?tags:_ fmt ->
            Fmt.pr ("%a " ^^ fmt ^^ " %!") pp_header ())
  else app_log ~src pp_header f

let success ?src f = app_log ?src (header `Green '+') f
let unhappy ?src f = app_log ?src (header `Red '!') f
let blank_line () = Logs.app (fun l -> l "")

let report_status status f =
  Logs.app (fun l ->
      f (fun ?header ?tags fmt ->
          l ?header ?tags ("%a " ^^ fmt) Text.Pp.status status))
