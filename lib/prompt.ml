let ask f =
  Logs.app (fun l -> f (fun ?header ?tags fmt -> l ?header ?tags (fmt ^^ " [Y/n]")))

let confirm ~question =
  let rec loop () =
    ask question;
    match String.lowercase_ascii (read_line ()) with
    | "" | "y" | "yes" -> true
    | "n" | "no" -> false
    | _ ->
        Logs.app
          (fun l ->
             l "Please answer with \"y\" for yes, \"n\" for no or just hit enter for the default");
        loop ()
  in
  loop ()

let confirm_or_abort ~question =
  if confirm ~question then
    Ok ()
  else
    Error (`Msg "Aborting on user demand")
