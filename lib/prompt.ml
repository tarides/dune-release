let ask f =
  App_log.question (fun l ->
      f (fun ?header ?tags fmt -> l ?header ?tags (fmt ^^ " [Y/n]")))

let confirm ~question ~yes =
  let rec loop () =
    ask question;
    match String.lowercase_ascii (read_line ()) with
    | "" | "y" | "yes" -> true
    | "n" | "no" -> false
    | _ ->
        App_log.unhappy (fun l ->
            l
              "Please answer with \"y\" for yes, \"n\" for no or just hit \
               enter for the default");
        loop ()
  in
  if yes then true else loop ()

let confirm_or_abort ?skippable ~question ~yes () =
  let is_skippable = match skippable with Some _ -> true | None -> false in
  let rec loop () =
    ask question;
    match String.lowercase_ascii (read_line ()) with
    | "" | "y" | "yes" -> `Yes
    | "n" | "no" -> `No
    | ("s" | "skip") when is_skippable -> `Skip
    | _ ->
        if is_skippable then
          App_log.unhappy (fun l ->
              l
                "Please answer with \"y\" for yes, \"n\" for no, \"s\" for \
                 skip or just hit enter for the default")
        else
          App_log.unhappy (fun l ->
              l
                "Please answer with \"y\" for yes, \"n\" for no or just hit \
                 enter for the default");
        loop ()
  in
  let input = if yes then `Yes else loop () in
  match input with
  | `Yes -> ( match skippable with Some f -> f () | None -> Ok () )
  | `Skip -> Ok ()
  | `No -> Error (`Msg "Aborting on user demand")
