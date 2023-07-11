open Caretaker

let o1 = "My main goal"
let o2 = "I'm not sure"
let c1 = Card.v ~title:"a" ~objective:o1 ~status:"Active" "card1"
let c2 = Card.v ~title:"b" ~objective:o1 ~status:"Active" "card2"
let c3 = Card.v ~title:"c" ~objective:o2 ~status:"Active" ""
let c4 = Card.v ~title:"c" ~objective:o1 ~status:"Active" "New KR"
let card = Alcotest.testable Card.pp ( = )
let cards = [ c1; c2; c3; c4 ]

let default_filter () =
  let x = Card.filter_out Filter.default_out cards in
  Alcotest.(check (list card)) __LOC__ [ c1; c2 ] x

let test_is () =
  let filter = [ (Column.Objective, Filter.is o1) ] in
  Alcotest.(check bool) "matches" true (Card.matches filter c1);
  let x = Card.filter_out filter cards in
  Alcotest.(check (list card)) __LOC__ [ c3 ] x

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

let test x y = Alcotest.test_case x `Quick y

let () =
  Alcotest.run "caretaker"
    [
      ("filters", [ test "default" default_filter; test "is" test_is ]);
      ("weeks", [ test "to_ints" weeks_to_ints; test "parse" parse_weeks ]);
    ]
