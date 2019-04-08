#!/usr/bin/env bash

PORT=$1

MONGOC="/usr/bin/mongo"

## detect auth
if [ -f ~/.mongodbauth.js ]; then
  MONGOOPT='--shell /root/.mongodbauth.js'
else
  MONGOOPT=''
fi

echo "WARNING: THIS PROCEDURE IS IRREVERSIBLE!!!"
echo "  continue? (y/n)"
read -n 1 vCONFIRM

if [ "$vCONFIRM" == "y" ]; then
  ## update statement
  STATEMENT='db.adminCommand({authSchemaUpgrade: 1});'
else
  echo "... canceled"
fi

echo "$STATEMENT" | $MONGOC $MONGOOPT -quiet -host $HOSTNAME -port $PORT


