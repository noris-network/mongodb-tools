#!/usr/bin/env bash

## gets arguments from run.sh
# list of dbs, comma seperated
db=$2
PORT=$1


MONGOC="/usr/bin/mongo"

## detect auth
if [ -f ~/.mongodbauth.js ]; then
  MONGOOPT='--shell /root/.mongodbauth.js'
else
  MONGOOPT=''
fi

if [ "$db" == "ALL" ]; then
STATEMENT="db = db.getSiblingDB('admin'); \
db.system.roles.find().forEach(printjson) \
"
echo "$STATEMENT" | $MONGOC $MONGOOPT -quiet -host $HOSTNAME -port $PORT
else

IFS=$'#'
for d in $db; do
STATEMENT="db = db.getSiblingDB('admin'); \
db.system.roles.find({ _id : { \$regex: /$d/ }}).forEach(printjson)
"
## fix quoting bug
unset IFS
echo "$STATEMENT" | $MONGOC $MONGOOPT -quiet -host $HOSTNAME -port $PORT
IFS=$'#'
done
unset IFS

fi

