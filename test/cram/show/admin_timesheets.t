
  $ caretaker show \
  >   --source admin \
  >   --admin-dir ../admin \
  >   --timesheets
  "Number","Id","Year","Month","Week","Days","Hours","User","Full Name","Funder","Entity Funder","Objective","Team","Category"
  "","KR123","2022","10","40","4.75","","eng1","","","","","",""
  "","KR123","2022","10","41","5","","eng1","","","","","",""
  "","KR123","2022","10","43","5","","eng1","","","","","",""
  "","KR123","2022","10","41","0.125","","eng2","","","","","",""
  "","KR123","2022","10","43","5","","eng2","","","","","",""

  $ caretaker show \
  >   --source admin \
  >   --admin-dir ../admin \
  >   --data-dir ../data \
  >   --timesheets
  "Number","Id","Year","Month","Week","Days","Hours","User","Full Name","Funder","Entity Funder","Objective","Team","Category"
  "","KR123","2022","10","40","4.75","","eng1","","<funder>","","<title>","<team>","<category>"
  "","KR123","2022","10","41","5","","eng1","","<funder>","","<title>","<team>","<category>"
  "","KR123","2022","10","43","5","","eng1","","<funder>","","<title>","<team>","<category>"
  "","KR123","2022","10","41","0.125","","eng2","","<funder>","","<title>","<team>","<category>"
  "","KR123","2022","10","43","5","","eng2","","<funder>","","<title>","<team>","<category>"
