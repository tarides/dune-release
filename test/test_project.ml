open Caretaker

let card x =
  Card.v ~title:"TITLE" ~objective:"OBEJCTIVE" ~status:"STATUS"
    ~labels:[ "LABEL1"; "LABEL2" ] ~team:"TEAM" ~pillar:"PILLAR"
    ~assignees:[ "A1"; "A2" ] ~quarter:"QUARTER" ~funder:"FUNDER"
    ~stakeholder:"STAKEHOLDER" ~size:"SIZE" ~tracks:[ "T1"; "T2" ]
    ~category:"CATEGORY" ~starts:"STARTS" ~ends:"ENDS" ~card_id:"CARD-ID"
    ~issue_id:"ISSUE-ID" ~project_id:"PROJECT-ID" ~issue_url:"ISSUE_URL"
    ~tracked_by:"TRACKED-BY"
    ~other_fields:[ ("K", "V"); ("A", "BC") ]
    x

let issue x = Issue.v ~title:"TITLE" ~body:"BODY" ~url:"URL" x

let t =
  Project.v ~title:"TITLE"
    ~cards:[ card "1"; card "2" ]
    ~goals:[ issue 1; issue 2 ]
    ~project_id:"PROJECT-ID" "test" 42

let project_t = Alcotest.testable Project.pp ( = )

let test_json () =
  let json = Project.to_json t in
  let x = Project.of_json json in
  Alcotest.(check project_t) __LOC__ t x

let tests = ("projects", [ Alcotest.test_case "json" `Quick test_json ])
