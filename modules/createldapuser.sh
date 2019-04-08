#!/usr/bin/env bash

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

## CREATE LDAP USER Statement using external SASL/LDAP Auth
STATEMENTCREATELDAPUSER="db.getSiblingDB(\"\$external\").createUser({ user : \"$mUSER\", roles: [ ${tmpVAR[@]} ]}) \
"

echo "$STATEMENTCREATELDAPUSER" | $MONGOC $MONGOOPT -quiet -host $HOSTNAME -port $PORT


