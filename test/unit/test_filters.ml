open Caretaker

let o1 = "My main goal"
let o2 = "I'm not sure"
let c1 = Card.v ~title:"a" ~objective:o1 ~status:"Active" "card1"
let c2 = Card.v ~title:"b" ~objective:o1 ~status:"Active" "card2"
let c3 = Card.v ~title:"c" ~objective:o2 ~status:"Active" ""
let c4 = Card.v ~title:"c" ~objective:o1 ~status:"Active" "New KR"
let card = Alcotest.testable Card.pp ( = )
let cards = [ c1; c2; c3; c4 ]

let f1 =
  let open Filter in
  [ (Column.Id, is ""); (Id, is "New KR") ]

let default_filter () =
  let x = Card.filter_out f1 cards in
  Alcotest.(check (list card)) __LOC__ [ c1; c2 ] x

let test_is () =
  let filter = [ (Column.Objective, Filter.is o1) ] in
  Alcotest.(check bool) "matches" true (Card.matches filter c1);
  let x = Card.filter_out filter cards in
  Alcotest.(check (list card)) __LOC__ [ c3 ] x

let test x y = Alcotest.test_case x `Quick y
let tests = ("filters", [ test "default" default_filter; test "is" test_is ])
