let () =
  Alcotest.run "caretaker"
    [
      Test_weeks.tests;
      Test_fields.tests;
      Test_issues.tests;
      Test_filters.tests;
      Test_card.tests;
      Test_project.tests;
      Test_diff.tests;
    ]
