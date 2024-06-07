open Caretaker

let body =
  {|
  Body

**Work Items**

```[tasklist]
### Work Items
- [ ] https://github.com/tarides/platform-roadmap/issues/241
- [ ] https://github.com/tarides/platform-roadmap/issues/95
- [ ] https://github.com/tarides/platform-roadmap/issues/242
- [ ] https://github.com/tarides/platform-roadmap/issues/243
- [ ] https://github.com/tarides/platform-roadmap/issues/244
- [ ] https://github.com/tarides/platform-roadmap/issues/245
- [ ] https://github.com/tarides/platform-roadmap/issues/93
- [ ] https://github.com/tarides/platform-roadmap/issues/76
- [ ] https://github.com/tarides/platform-roadmap/issues/28
- [ ] https://github.com/tarides/platform-roadmap/issues/27
- [ ] https://github.com/tarides/platform-roadmap/issues/17
- [ ] https://github.com/tarides/platform-roadmap/issues/75
- [ ] https://github.com/tarides/platform-roadmap/issues/74
- [ ] https://github.com/tarides/platform-roadmap/issues/73
- [ ] https://github.com/tarides/platform-roadmap/issues/92
- [ ] https://github.com/tarides/platform-roadmap/issues/72
- [ ] https://github.com/tarides/platform-roadmap/issues/71
- [ ] https://github.com/tarides/platform-roadmap/issues/91
```
  |}

let body0 = {|
  Body

**Work Items**

|}

let body2 =
  {|
  Body

**Work Items**

```[tasklist]
### Work Items
- [ ] https://github.com/tarides/platform-roadmap/issues/666
```
  |}

let body3 =
  {|
  Body

**Work Items**

```[tasklist]
### Work Items
- [ ] https://github.com/tarides/platform-roadmap/issues/666
- [ ] https://github.com/tarides/platform-roadmap/issues/667
```
  |}

let c666 = "https://github.com/tarides/platform-roadmap/issues/666"
let c667 = "https://github.com/tarides/platform-roadmap/issues/667"

let lines =
  let pp = Fmt.lines in
  let equal = String.equal in
  Alcotest.testable pp equal

let test_tracked_issues () =
  let t = Issue.v ~body 12 in
  let t0 = Issue.v ~body:body0 12 in
  let t2 = Issue.v ~body:body2 12 in
  let t3 = Issue.v ~body:body3 12 in
  let x0 = Issue.with_tracks t [] in

  let x2 = Issue.with_tracks t [ c666 ] in
  let x3 = Issue.with_tracks t [ c666; c667 ] in
  Alcotest.check lines __LOC__ (Issue.body t0) (Issue.body x0);
  Alcotest.check lines __LOC__ (Issue.body t2) (Issue.body x2);
  Alcotest.check lines __LOC__ (Issue.body t3) (Issue.body x3)

let issue_t = Alcotest.testable Issue.pp ( = )

let test_json () =
  let t =
    Issue.v ~title:"TITLE" ~body:"BODY ```[tasklit]\n- [ ] foo\n```\n"
      ~url:"bar" ~closed:true 42
  in
  let j = Issue.to_json t in
  let y = Issue.of_json j in
  Alcotest.(check issue_t) __LOC__ t y

let tests =
  ( "issues",
    [
      Alcotest.test_case "tracks" `Quick test_tracked_issues;
      Alcotest.test_case "json" `Quick test_json;
    ] )
