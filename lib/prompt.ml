type answer = Yes | No

let ask f ~default_answer =
  let options : ('a, Format.formatter, unit, unit) format4 =
    match default_answer with Yes -> " [Y/n]" | No -> " [y/N]"
  in
  App_log.question (fun l ->
      f (fun ?header ?tags fmt -> l ?header ?tags (fmt ^^ options)))

let rec loop ~question ~default_answer =
  ask question ~default_answer;
  match String.lowercase_ascii (read_line ()) with
  | "" when default_answer = Yes -> true
  | "" when default_answer = No -> false
  | "y" | "yes" -> true
  | "n" | "no" -> false
  | _ ->
      App_log.unhappy (fun l ->
          l
            "Please answer with \"y\" for yes, \"n\" for no or just hit enter \
             for the default");
      loop ~question ~default_answer

let confirm ~question ~yes ~default_answer =
  if yes then true else loop ~question ~default_answer

let confirm_or_abort ~question ~yes ~default_answer =
  if confirm ~question ~yes ~default_answer then Ok ()
  else Error (`Msg "Aborting on user demand")
