module Choice = struct
  type 'a t = { short : string; long : string; value : 'a }

  let yes = { short = "y"; long = "yes"; value = `Yes }

  let no = { short = "n"; long = "no"; value = `No }

  let skip = { short = "s"; long = "skip"; value = `Skip }
end

module Choices = struct
  type 'a t = {
    choices : 'a Choice.t list;
    hint : (unit, Format.formatter, unit) format;
    help : (unit, Format.formatter, unit) format;
  }

  let yes_no =
    let choices = [ Choice.yes; Choice.no ] in
    { choices; hint = "[Y/n]"; help = "\"y\" for yes, \"n\" for no" }

  let yes_no_skip =
    let choices = [ Choice.yes; Choice.no; Choice.skip ] in
    { choices; hint = "[Y/n/s]"; help = yes_no.help ^^ ", \"s\" for skip" }
end

let ask (choices : _ Choices.t) (f : ('a, unit) Logs.msgf) =
  App_log.question (fun l ->
      f (fun ?header ?tags fmt -> l ?header ?tags (fmt ^^ " " ^^ choices.hint)))

let rec choice ~default ~question choices =
  ask choices question;
  let input = String.lowercase_ascii (read_line ()) in
  if String.equal input "" then default
  else
    let in_choices x =
      String.equal input x.Choice.short || String.equal input x.Choice.long
    in
    match List.find_opt in_choices choices.choices with
    | Some x -> x.value
    | None ->
        App_log.unhappy (fun l ->
            l
              ( "Please answer with " ^^ choices.help
              ^^ " or just hit enter for the default" ));
        choice ~default ~question choices

let confirm ~question ~yes =
  let choices = Choices.yes_no in
  match if yes then `Yes else choice ~default:`Yes ~question choices with
  | `Yes -> true
  | `No -> false

let confirm_or_abort ~question ~yes =
  if confirm ~question ~yes then Ok ()
  else Error (`Msg "Aborting on user demand")

let confirm_or_abort_or_skip ~f ~question ~yes =
  let choices = Choices.yes_no_skip in
  match if yes then `Yes else choice ~default:`Yes ~question choices with
  | `Yes -> f ()
  | `Skip -> Ok ()
  | `No -> Error (`Msg "Aborting on user demand")
