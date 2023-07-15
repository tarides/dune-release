open Caretaker

let weeks_to_ints () =
  let all = Weeks.all in
  let quarters = Weeks.(union [ q1; q3; q2; q4 ]) in
  let range = Weeks.range 1 52 in
  Alcotest.(check (list int))
    __LOC__ (Weeks.to_ints all) (Weeks.to_ints quarters);
  Alcotest.(check (list int)) __LOC__ (Weeks.to_ints all) (Weeks.to_ints range);
  Alcotest.(check (list int))
    __LOC__ [ 1; 2; 3; 4 ]
    (Weeks.to_ints (Weeks.range 1 4));
  Alcotest.(check (list int))
    __LOC__ [ 1; 2; 3; 4 ]
    (Weeks.to_ints Weeks.(union [ range 1 3; range 2 4; week 2 ]));
  ()

let parse_weeks () =
  let get = function Error (`Msg e) -> Alcotest.fail e | Ok s -> s in
  let s1 = get (Weeks.of_string "1") in
  Alcotest.(check (list int)) __LOC__ [ 1 ] (Weeks.to_ints s1);
  let s2 = get (Weeks.of_string "q4,12-14,1") in
  Alcotest.(check (list int))
    __LOC__
    [ 1; 12; 13; 14; 40; 41; 42; 43; 44; 45; 46; 47; 48; 49; 50; 51; 52 ]
    (Weeks.to_ints s2)

let tests =
  ( "weeks",
    [
      Alcotest.test_case "to_ints" `Quick weeks_to_ints;
      Alcotest.test_case "parse" `Quick parse_weeks;
    ] )
