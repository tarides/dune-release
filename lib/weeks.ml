type t =
  | All
  | Q1
  | Q2
  | Q3
  | Q4
  | Week of int
  | Range of int * int
  | Union of t list

let rec pp ppf = function
  | All -> Fmt.pf ppf "all"
  | Q1 -> Fmt.pf ppf "q1"
  | Q2 -> Fmt.pf ppf "q2"
  | Q3 -> Fmt.pf ppf "q3"
  | Q4 -> Fmt.pf ppf "q4"
  | Week i -> Fmt.pf ppf "%d" i
  | Range (x, y) -> Fmt.pf ppf "%d-%d" x y
  | Union xs -> Fmt.list ~sep:(Fmt.any ",") pp ppf xs

let range_of_string s =
  match String.split_on_char '-' s with
  | [ s ] -> (
      match int_of_string_opt s with
      | None -> Fmt.kstr (fun e -> Error (`Msg e)) "invalid int: %S" s
      | Some d -> Ok (Week d))
  | [ x; y ] -> (
      try Ok (Range (int_of_string x, int_of_string y))
      with Failure s -> Error (`Msg s))
  | _ -> Fmt.kstr (fun e -> Error (`Msg e)) "invalid range: %S" s

let rec of_string = function
  | "all" -> Ok All
  | "q1" -> Ok Q1
  | "q2" -> Ok Q2
  | "q3" -> Ok Q3
  | "q4" -> Ok Q4
  | s -> (
      match String.split_on_char ',' s with
      | [ s ] -> range_of_string s
      | xs -> (
          match
            List.fold_left
              (fun acc x ->
                match (acc, of_string x) with
                | Ok acc, Ok y -> Ok (y :: acc)
                | Error e, _ | _, Error e -> Error e)
              (Ok []) xs
          with
          | Ok ys -> Ok (Union ys)
          | Error e -> Error e))

let of_string s = of_string (String.lowercase_ascii s)
let all_r = Range (1, 52)
let q1_r = Range (1, 13)
let q2_r = Range (14, 26)
let q3_r = Range (27, 39)
let q4_r = Range (40, 52)

let rec to_ints = function
  | All -> to_ints all_r
  | Q1 -> to_ints q1_r
  | Q2 -> to_ints q2_r
  | Q3 -> to_ints q3_r
  | Q4 -> to_ints q4_r
  | Week i -> [ i ]
  | Range (i, j) -> List.init (j - i + 1) (fun x -> i + x)
  | Union xs -> List.sort_uniq compare (List.flatten (List.map to_ints xs))

let all = All
let q1 = Q1
let q2 = Q2
let q3 = Q3
let q4 = Q4
let week i = Week i
let range x y = Range (x, y)
let union xs = Union xs
