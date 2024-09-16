
  $ caretaker fetch \
  >   --source admin \
  >   --admin-dir ../admin
  caretaker: [INFO] Writing data/timesheets.csv

  $ cat data/timesheets.csv
  "Number","Id","Year","Month","Week","Days","Hours","User","Full Name","Funder","Entity Funder","Objective","Team","Category"
  "","KR123","2022","10","40","4.75","","eng1","","","","","",""
  "","KR123","2022","10","41","5","","eng1","","","","","",""
  "","KR123","2022","10","43","5","","eng1","","","","","",""
  "","KR123","2022","10","41","0.125","","eng2","","","","","",""
  "","KR123","2022","10","43","5","","eng2","","","","","",""

We cannot overwrite files in the [../data] directory from this test,
so we copy the files in a temporary [tmp] directory.

  $ mkdir tmp
  $ cp ../data/tarides-27.json tmp

  $ caretaker fetch \
  >   --source admin \
  >   --admin-dir ../admin \
  >   --data-dir tmp
  caretaker: [INFO] Writing tmp/timesheets.csv

  $ cat tmp/timesheets.csv
  "Number","Id","Year","Month","Week","Days","Hours","User","Full Name","Funder","Entity Funder","Objective","Team","Category"
  "","KR123","2022","10","40","4.75","","eng1","","<funder>","","<title>","<team>","<category>"
  "","KR123","2022","10","41","5","","eng1","","<funder>","","<title>","<team>","<category>"
  "","KR123","2022","10","43","5","","eng1","","<funder>","","<title>","<team>","<category>"
  "","KR123","2022","10","41","0.125","","eng2","","<funder>","","<title>","<team>","<category>"
  "","KR123","2022","10","43","5","","eng2","","<funder>","","<title>","<team>","<category>"

  $ cat tmp/tarides-27.json
  {
    "org": "<org>",
    "number": 27,
    "title": "<title>",
    "cards": [
      {
        "title": "<title>",
        "id": "KR123",
        "objective": "",
        "status": "<status>",
        "labels": ["<label-1>", "<label-2>"],
        "team": "<team>",
        "pillar": "<pillar>",
        "assignees": ["<assignee>"],
        "iteration": "<iteration>",
        "funder": "<funder>",
        "stakeholder": "",
        "size": "",
        "category": "<category>",
        "tracks": [],
        "starts": "<starts>",
        "ends": "<ends>",
        "progress": "<progress>",
        "other-fields": {
          "effort days": "117.",
          "junior fte": "2.6",
          "senior fte": "10.4",
          "principal fte": "7.8",
          "priority": "<priority>",
          "end on quarter": "<end-on-quarter>",
          "duration (weeks)": "24.",
          "start on quarter": "<start-on-quarter>",
          "js bucket": "<js-bucket>",
          "contact": "<contact>",
          "owner": "<owner>",
          "slack channel": "<slack-channel>",
          "proposal link": "<proposal-link>",
          "proposal status": "Active",
          "repository": "<repository>"
        },
        "project-id": "<project-id>",
        "card-id": "<card-id>",
        "issue-id": "<issue-id>",
        "issue-url": "<issue-url>",
        "state": "open",
        "tracked-by": ""
      },
      {
        "title": "<title>",
        "id": "KR000",
        "objective": "",
        "status": "<status>",
        "labels": ["<label-1>", "<label-2>", "legacy"],
        "team": "<team>",
        "pillar": "<pillar>",
        "assignees": ["<assignee>"],
        "iteration": "<iteration>",
        "funder": "<funder>",
        "stakeholder": "",
        "size": "",
        "category": "<category>",
        "tracks": [],
        "starts": "<starts>",
        "ends": "<ends>",
        "progress": "<progress>",
        "other-fields": {
          "effort days": "117.",
          "junior fte": "2.6",
          "senior fte": "10.4",
          "principal fte": "7.8",
          "priority": "<priority>",
          "end on quarter": "<end-on-quarter>",
          "duration (weeks)": "24.",
          "start on quarter": "<start-on-quarter>",
          "js bucket": "<js-bucket>",
          "contact": "<contact>",
          "owner": "<owner>",
          "slack channel": "<slack-channel>",
          "proposal link": "<proposal-link>",
          "proposal status": "Active",
          "repository": "<repository>"
        },
        "project-id": "<project-id>",
        "card-id": "<card-id>",
        "issue-id": "<issue-id>",
        "issue-url": "<issue-url>",
        "state": "open",
        "tracked-by": ""
      }
    ],
    "fields": [],
    "project-id": "<project-id>",
    "goals": []
  }
