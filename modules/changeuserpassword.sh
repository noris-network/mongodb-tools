#!/usr/bin/env bash

## gets arguments from run.sh
### takes four arguments, ARG1=PORT ARG2=AUTHDB ARG3=mUSER ARG4=mPASS
PORT=$1
AUTHDB=$2
mUSER=$3
mPASS=$4

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

## Change User PAssword using AuthDB $AUTHDB
STATEMENTUPDATEUSER="db = db.getSiblingDB('$AUTHDB'); \
db.changeUserPassword(\"$mUSER\", \"$mPASS\") \
"

echo "$STATEMENTUPDATEUSER" | $MONGOC $MONGOOPT -quiet -host $HOSTNAME -port $PORT

## mongo shell always gives exit code zero
## todo asign variable from output and check for empty var
#if [ $? == 0 ]; then echo success; fi

