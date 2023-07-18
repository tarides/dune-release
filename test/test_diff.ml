open Caretaker

let body0 = {|
  Body

**Work Items**

|}

let body1 =
  {|
  Body

**Work Items**

```[tasklist]
### Work Items
- [ ] ISSUE1
- [ ] ISSUE2
- [ ] ISSUE3
- [ ] OTHER-ISSUE
```
  |}

let body2 =
  {|
  Body

**Work Items**

```[tasklist]
### Work Items
- [ ] ISSUE1
- [ ] ISSUE2
- [ ] ISSUE3
```
  |}

let body3 =
  {|
  Body

**Work Items**

```[tasklist]
### Work Items
- [ ] OTHER-ISSUE
```
  |}

let issue1 = "ISSUE1"
let issue2 = "ISSUE2"
let issue3 = "ISSUE3"
let state = function `Open -> false | `Closed -> true

let pp_state ppf = function
  | `Open -> Fmt.string ppf "open"
  | `Closed -> Fmt.string ppf "closed"

let g0 s = Issue.v ~body:body0 ~closed:(state s) 0
let g1 s = Issue.v ~body:body1 ~closed:(state s) 1
let g2 s = Issue.v ~body:body2 ~closed:(state s) 2
let g3 s = Issue.v ~body:body3 ~closed:(state s) 3

let c1 s =
  Card.v ~issue_url:issue1 ~issue_closed:(state s) ~title:"TITLE1"
    ~objective:"OBJB1" "ID1"

let c2 s =
  Card.v ~issue_url:issue2 ~issue_closed:(state s) ~title:"TITLE2"
    ~objective:"OBJ2" "ID2"

let c3 s =
  Card.v ~issue_url:issue3 ~issue_closed:(state s) ~title:"TITLE3"
    ~objective:"OBJ3" "ID3"

let diff = Alcotest.testable Diff.pp ( = )

let test_goals () =
  let check_empty issues state =
    Fmt.epr "expected state: %a@.%a\n" pp_state state
      Fmt.Dump.(list Card.pp)
      issues;
    let d0 = Diff.of_goal issues (g0 state) in
    Alcotest.(check diff) __LOC__ Diff.empty d0;
    let d1 = Diff.of_goal issues (g1 state) in
    Alcotest.(check diff) __LOC__ Diff.empty d1;
    let d2 = Diff.of_goal issues (g2 state) in
    Alcotest.(check diff) __LOC__ Diff.empty d2;
    let d3 = Diff.of_goal issues (g3 state) in
    Alcotest.(check diff) __LOC__ Diff.empty d3
  in

  check_empty [ c1 `Open; c2 `Open; c3 `Open ] `Open;
  check_empty [ c1 `Closed; c2 `Open; c3 `Open ] `Open;
  check_empty [ c1 `Closed; c2 `Closed; c3 `Open ] `Open;
  check_empty [ c1 `Open; c2 `Open; c3 `Open ] `Open;
  check_empty [ c1 `Closed; c2 `Closed; c3 `Closed ] `Closed;
  check_empty [ c1 `Closed; c2 `Closed; c3 `Closed ] `Closed

let test_status () =
  let card s status =
    Card.v ~issue_url:issue1 ~issue_closed:(state s) ~title:"TITLE1"
      ~objective:"OBJB1" "ID1" ~status
  in
  let c = card `Closed "" in
  let d = Diff.of_card c in
  let e = Diff.state ~id:"ID1" ~issue_id:"" ~set:`Open ~status:"" in
  Alcotest.(check diff) __LOC__ e d;

  let c = card `Closed "active" in
  let d = Diff.of_card c in
  let e = Diff.state ~id:"ID1" ~issue_id:"" ~set:`Open ~status:"active" in
  Alcotest.(check diff) __LOC__ e d;

  let c = card `Closed "complete" in
  let d = Diff.of_card c in
  Alcotest.(check diff) __LOC__ Diff.empty d

let tests =
  ( "diffs",
    [
      Alcotest.test_case "goals" `Quick test_goals;
      Alcotest.test_case "status" `Quick test_status;
    ] )
