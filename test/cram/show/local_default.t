
  $ caretaker show \
  >   --source local \
  >   --data-dir ../data
  org: tarides
  
  == Project (25) ==
  
  $ caretaker show \
  >   --source local \
  >   --data-dir ../data \
  >   --number 27
  org: tarides
  
  == <title> (27) ==
    [  KR123] <title> (open)
      Status    : <status>
      Iteration : <iteration>
      Starts    : <starts>
      Ends      : <ends>
      Team      : <team>
      Funder    : <funder>
      effort days*: 117.
      junior fte*: 2.6
      senior fte*: 10.4
      principal fte*: 7.8
      priority* : <priority>
      end on quarter*: <end-on-quarter>
      duration (weeks)*: 24.
      start on quarter*: <start-on-quarter>
      js bucket*: <js-bucket>
      contact*  : <contact>
      owner*    : <owner>
      slack channel*: <slack-channel>
      proposal link*: <proposal-link>
      proposal status*: Active
      repository*: <repository>
  
  $ caretaker show \
  >   --source local \
  >   --data-dir ../data \
  >   --number 27 \
  >   --format csv
  "id","title","proposal link","funder","status","pillar","owner","contact","js bucket","start on quarter","duration (weeks)","end on quarter","starts","ends","priority","principal fte","senior fte","junior fte","effort days","slack channel"
  "KR123","<title>","<proposal-link>","<funder>","<status>","<pillar>","<owner>","<contact>","<js-bucket>","<start-on-quarter>","24.","<end-on-quarter>","<starts>","<ends>","<priority>","7.8","10.4","2.6","117.","<slack-channel>"
