#!/usr/bin/env bash

## gets arguments from run.sh
db=$2
PORT=$1
mROLE=$3

## detect auth
if [ -f ~/.mongodbauth.js ]; then
  MONGOC='mongo --shell /root/.mongodbauth.js'
else
  MONGOC='mongo'
fi


## add version detection
#MONGOVERSION=$(mongo -version | awk '{ print $4 }')


#if [[ "$MONGOVERSION" =~ .*3.0.* ]]; then
  ## role create statement
  ## v3.0
  STATEMENT="db = db.getSiblingDB('$db'); db.dropRole(\"$mROLE\", {w: \"majority\", wtimeout: 5000})"

#if [ -z "$STATEMENTCREATEROLE" ]; then echo "ERROR: $MONGOVERSION"; exit 1; fi

## execute
echo "$STATEMENT" | $MONGOC -quiet -host $HOSTNAME -port $PORT


