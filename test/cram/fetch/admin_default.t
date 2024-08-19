
  $ cat data/timesheets.csv
  cat: data/timesheets.csv: No such file or directory
  [1]

  $ caretaker fetch --source admin --admin-dir ../admin
  Writing data/timesheets.csv

  $ cat data/timesheets.csv
  "Number","Id","Year","Month","Week","Days","Hours","User","Full Name","Funder","Entity Funder","Work Item","Team","Category","Objective"
  "","KR123","2022","10","40","4.75","","eng1","","","","","","",""
  "","KR123","2022","10","41","5","","eng1","","","","","","",""
  "","KR123","2022","10","43","5","","eng1","","","","","","",""
  "","KR123","2022","10","41","0.125","","eng2","","","","","","",""
  "","KR123","2022","10","43","5","","eng2","","","","","","",""
