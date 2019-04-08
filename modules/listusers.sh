#!/usr/bin/env bash

## gets arguments from run.sh
# list of dbs, comma seperated
PORT=$1
AUTHDB=$2
mUSER=$3

MONGOC="/usr/bin/mongo"

## detect auth
if [ -f ~/.mongodbauth.js ]; then
  MONGOOPT='--shell /root/.mongodbauth.js'
else
  MONGOOPT=''
fi

if [ "$mUSER" == "ALL" ]; then
  if [ "$AUTHDB" == "ALL" ]; then
STATEMENT="db = db.getSiblingDB('admin'); \
db.system.users.find().forEach(printjson) \
"
  else
STATEMENT="db = db.getSiblingDB('admin'); \
db.system.users.find({ _id : { \$regex: /${AUTHDB}./ }}).forEach(printjson)
"
  fi
else
STATEMENT="db = db.getSiblingDB('admin'); \
db.system.users.find({ _id : { \$regex: /${AUTHDB}.$mUSER/ }}).forEach(printjson)
"
fi

echo "$STATEMENT" | $MONGOC $MONGOOPT -quiet -host $HOSTNAME -port $PORT

