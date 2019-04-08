#!/usr/bin/env bash
#set -x
## gets arguments from run.sh
# list of dbs, comma seperated
db=$1
PORT=$2
AUTHDB=$3
mUSER=$4
mROLE=$5

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
db.grantRolesToUser( \"$mUSER\", [ ${tmpVAR[@]} ], { w: \"majority\" , wtimeout: 4000 } )
"

echo "$STATEMENTCREATEUSER" | $MONGOC $MONGOOPT -quiet -host $HOSTNAME -port $PORT

