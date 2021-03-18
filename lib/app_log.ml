let header style c fmt () =
  Fmt.string fmt "[";
  Fmt.(styled style (const char c)) fmt ();
  Fmt.string fmt "]"

let app_log ?src pp_header f =
  Logs.app ?src (fun l ->
      f (fun ?header ?tags fmt -> l ?header ?tags ("%a " ^^ fmt) pp_header ()))

let status ?src f = app_log ?src (header `Yellow '-') f

let question ?src f = app_log ?src (header `Magenta '?') f

let success ?src f = app_log ?src (header `Green '+') f

let unhappy ?src f = app_log ?src (header `Red '!') f

let blank_line () = Logs.app (fun l -> l "")

let report_status status f =
  Logs.app (fun l ->
      f (fun ?header ?tags fmt ->
          l ?header ?tags ("%a " ^^ fmt) Text.Pp.status status))
