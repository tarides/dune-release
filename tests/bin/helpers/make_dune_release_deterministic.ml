open Re

let hex = alt [ rg 'a' 'f'; digit ]

(* git describe returns g *)
let shorthash = seq [ char 'g'; rep hex ]

let dash = char '-'

let without_dash = diff any dash

let pkg_name = rep without_dash

let version = rep without_dash

let version_set =
  [ group @@ version; group dash; group @@ rep digit; group dash; shorthash ]

let make_build_deterministic line =
  let re =
    compile @@ seq
    @@ [ group @@ str "_build/"; group @@ rep pkg_name; group dash ]
    @ version_set
  in
  replace re
    ~f:(fun group ->
      let build = Group.get group 1 in
      let pkg_name = Group.get group 2 in
      let dash = Group.get group 3 in
      let ver = Group.get group 4 in
      let dash2 = Group.get group 5 in
      let since = Group.get group 6 in
      let dash3 = Group.get group 7 in
      let commit = "<deterministic>" in
      let replacement =
        Format.asprintf "%sPKG(%s)%sVER(%s)%sSINCE(%s)%sCOMMIT(%s)" build
          pkg_name dash ver dash2 since dash3 commit
      in
      replacement)
    line

let make_commit_deterministic line =
  let re = compile @@ seq [ str "Commit "; rep hex ] in
  replace_string re ~by:"Commit <deterministic>" line

let make_distribution_deterministic line =
  let re =
    compile @@ seq
    @@ [ group @@ str "Distribution for "; group @@ rep pkg_name; group space ]
    @ version_set
  in
  replace re
    ~f:(fun group ->
      let dist_for = Group.get group 1 in
      let pkg_name = Group.get group 2 in
      let space = Group.get group 3 in
      let ver = Group.get group 4 in
      let dash2 = Group.get group 5 in
      let since = Group.get group 6 in
      let dash3 = Group.get group 7 in
      let commit = "<deterministic>" in
      let replacement =
        Format.asprintf "%sPKG(%s)%sVER(%s)%sSINCE(%s)%sCOMMIT(%s)" dist_for
          pkg_name space ver dash2 since dash3 commit
      in
      replacement)
    line

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
      () |> read_line |> make_build_deterministic |> make_commit_deterministic
      |> make_distribution_deterministic |> make_lint_directory_deterministic
      |> make_test_directory_deterministic |> print_endline
    done
  with End_of_file -> ()
