COMMIT=`git rev-parse HEAD`
COMMIT_SHORT=`git rev-parse --short HEAD`

sed -e "s/$COMMIT/\$COMMIT/" -e "s/$COMMIT_SHORT/\$COMMIT_SHORT/" -e '/\(=> read *\)[^ ]*/d'
