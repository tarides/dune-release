
  $ cat data/timesheets.csv
  cat: data/timesheets.csv: No such file or directory
  [1]

  $ caretaker fetch --source admin --admin-dir ../admin
  Writing data/timesheets.csv

  $ cat data/timesheets.csv
  "Id","Year","Month","Week","User","Days"
  "KR123","2022","10","40","eng1","5.0"
  "KR123","2022","10","41","eng1","5.0"
  "KR123","2022","10","43","eng1","5.0"
  "KR123","2022","10","41","eng2","1.0"
  "KR123","2022","10","43","eng2","5.0"
