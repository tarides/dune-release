Default fields:

  $ caretaker show \
  >   --source local \
  >   --data-dir ../data \
  >   --timesheets
  "Number","Id","Year","Month","Week","Days","Hours","User","Full Name","Funder","Entity Funder","Objective","Team","Category"
  "","KR123","2022","10","40","5","","eng1","","","","","",""
  "","KR123","2022","10","41","1","","eng1","","","","","",""
  "","KR123","2022","10","41","5","","eng1","","","","","",""
  "","KR123","2022","10","43","5","","eng1","","","","","",""
  "","KR123","2022","10","43","5","","eng1","","","","","",""

With custom fields:

  $ caretaker show \
  >   --source local \
  >   --data-dir ../data \
  >   --fields 'Id,Year,User,Days' \
  >   --timesheets
  "Id","Year","User","Days"
  "KR123","2022","eng1","5"
  "KR123","2022","eng1","1"
  "KR123","2022","eng1","5"
  "KR123","2022","eng1","5"
  "KR123","2022","eng1","5"
