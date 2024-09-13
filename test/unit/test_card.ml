open Caretaker

let card =
  Card.v ~title:"TITLE" ~objective:"OBEJCTIVE" ~status:"STATUS"
    ~labels:[ "LABEL1"; "LABEL2" ] ~team:"TEAM" ~pillar:"PILLAR"
    ~assignees:[ "A1"; "A2" ] ~iteration:"ITERATION" ~funder:"FUNDER"
    ~stakeholder:"STAKEHOLDER" ~size:"SIZE" ~tracks:[ "T1"; "T2" ]
    ~category:"CATEGORY" ~starts:"STARTS" ~ends:"ENDS" ~card_id:"CARD-ID"
    ~issue_id:"ISSUE-ID" ~project_id:"PROJECT-ID" ~issue_url:"ISSUE_URL"
    ~tracked_by:"TRACKED-BY" ~progress:"PROGRESS"
    ~other_fields:[ ("K", "V"); ("A", "BC") ]
    "CARD"

let card_t = Alcotest.testable Card.pp ( = )

let test_json () =
  let json = Card.to_json card in
  let x = Card.of_json ~project_id:"PROJECT-ID" json in
  Alcotest.(check card_t) __LOC__ card x

let tests = ("cards", [ Alcotest.test_case "json" `Quick test_json ])
