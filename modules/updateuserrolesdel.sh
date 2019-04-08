#!/usr/bin/env bash

## gets arguments from run.sh
# list of dbs, comma seperated
db=$1
PORT=$2
AUTHDB=$3
mUSER=$4
mPASS=$5
mROLE=$6

echo "not implemented"
exit 255


MONGOC="/usr/bin/mongo"

## detect auth
if [ -f ~/.mongodbauth.js ]; then
  MONGOOPT='--shell /root/.mongodbauth.js'
else
  MONGOOPT=''
fi

IFS=$'#'
for d in $db; do
  tmpVAR[$counter]="{ role: \"$mROLE\", db: \"$d\" },"
  let counter+=1
done
unset IFS

#debug
#echo ${tmpVAR[@]}

## CREATE USER Statement using AuthDB $AUTHDB
STATEMENTCREATEUSER="db = db.getSiblingDB('$AUTHDB'); \
db.createUser({ user: \"$mUSER\", pwd: \"$mPASS\", roles: [ ${tmpVAR[@]} ]}) \
"

echo "$STATEMENTCREATEUSER" | $MONGOC $MONGOOPT -quiet -host $HOSTNAME -port $PORT

