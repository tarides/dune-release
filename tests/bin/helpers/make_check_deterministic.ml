open Re

let make_lint_directory_deterministic line =
  (* OCaml implementation of bash's
     sed "s/lint of .* and/lint of <project_dir> and/" *)
  let re = compile @@ seq [ str "lint of "; rep any; str " and" ] in
  replace_string re ~by:"lint of <project_dir> and" line

let make_test_directory_deterministic line =
  (* Replace Sys.getcwd by <test_directory> *)
  let re = compile @@ str (Sys.getcwd ()) in
  replace_string re ~by:"<test_directory>" line

let rewrite_windows_paths line =
  if Sys.win32 then
    (* - Locate paths (from _build or .\ until end of line)
        - in that, replace \ by / *)
    let re = compile @@ seq [alt [str "_build";str ".\\"]; rep any; eol] in
    replace re line ~f:(fun group ->
        let matched = Group.get group 0 in
        replace_string (compile (char '\\')) ~by:"/" matched
      )
  else
    line

let () =
  try
    while true do
      let line = read_line () in
      make_lint_directory_deterministic line
      |> make_test_directory_deterministic
      |> rewrite_windows_paths
      |> print_endline
    done
  with End_of_file -> ()
