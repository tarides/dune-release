open Re

let make_lint_directory_deterministic line =
  (* OCaml implementation of bash's
     sed "s/lint of .* and/lint of <project_dir> and/" *)
  let re = compile @@ seq [ str "lint of "; rep any; str " and" ] in
  replace_string re ~by:"lint of <project_dir> and" line

let make_test_directory_deterministic line =
  (* OCaml implementation of bash's
     sed 's/\/.*\/tests\/bin\/check/<test_directory>/' *)
  let re = compile @@ seq [ str "/"; rep any; str "/tests/bin/check" ] in
  replace_string re ~by:"<test_directory>" line

let () =
  try
    while true do
      let line = read_line () in
      make_lint_directory_deterministic line
      |> make_test_directory_deterministic |> print_endline
    done
  with End_of_file -> ()
