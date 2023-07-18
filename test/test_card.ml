open Caretaker

let card =
  Card.v ~title:"TITLE" ~objective:"OBEJCTIVE" ~status:"STATUS" ~team:"TEAM"
    ~funder:"FUNDER" ~pillar:"PILLAR" ~stakeholder:"STAKEHOLDER"
    ~category:"CATEGORY" ~schedule:"SCHEDULE" ~starts:"STARTS" ~ends:"ENDS"
    ~card_id:"CARD-ID" ~issue_id:"ISSUE-ID" ~project_id:"PROJECT-ID"
    ~issue_url:"ISSUE_URL" ~tracked_by:"TRACKED-BY"
    ~other_fields:[ ("K", "V"); ("A", "BC") ]
    ~issue_closed:true "CARD"

let card_t = Alcotest.testable Card.pp ( = )

let test_json () =
  let json = Card.to_json card in
  let x =
    Card.of_json ~project_id:"PROJECT-ID" ~fields:(Fields.empty ()) json
  in
  Alcotest.(check card_t) __LOC__ card x

let tests = ("cards", [ Alcotest.test_case "json" `Quick test_json ])
