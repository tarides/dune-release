
We cannot overwrite files in the [../data] directory from this test,
so we copy the files in a temporary [tmp] directory.

  $ mkdir tmp
  $ cp ../data/tarides-27.json tmp

  $ caretaker fetch \
  >   --source local \
  >   --data-dir tmp

  $ cat tmp/timesheets.csv
  cat: tmp/timesheets.csv: No such file or directory
  [1]

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
        "quarter": "<quarter>",
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
