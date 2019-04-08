#!/usr/bin/env bash
# creates roles per database! https://docs.mongodb.org/manual/tutorial/manage-users-and-roles/#create-a-user-defined-role
# ToDo: add dynamic permissions through script option

## gets arguments from run.sh
db=$1
PORT=$2
mROLE=$3


MONGOC="/usr/bin/mongo"

## detect auth
if [ -f ~/.mongodbauth.js ]; then
  MONGOOPT='--shell /root/.mongodbauth.js'
else
  MONGOOPT=''
fi

## add version detection
MONGOVERSION=$(mongo -version | awk '{ print $4 }')


case "$mROLE" in
  "readWriteSecure")
  if [[ "$MONGOVERSION" =~ .*2.6.* ]]; then
    ## v2.6 - for testing on workstation
    STATEMENTCREATEROLE="db = db.getSiblingDB('$db'); \
    db.createRole( \
    { role: '$mROLE', privileges: [ { resource: { db: '$db', collection: '' }, actions: [ 'insert', 'remove', 'update', 'find', 'createIndex' ] } ], roles: [] } \
    )"
  else
    ## role create statement
    ## v3.x
    STATEMENTCREATEROLE="db = db.getSiblingDB('$db'); \
    db.createRole( \
    { role: '$mROLE', privileges: [ { resource: { db: '$db', collection: '' }, actions: [ 'collStats', 'createCollection', 'dbHash', 'dbStats', 'createIndex', 'find', 'insert', 'killCursors', 'listIndexes', 'listCollections', 'remove', 'update' ] } ], roles: [] } \
  )"
  fi
    ;;
  *)
    ## den case aendern, so dass default roles auch verwendet werden koennen
    echo "ERROR: Role not specified as template in $0 ... doing nothing"
    ;;
esac


if [ -z "$STATEMENTCREATEROLE" ]; then echo "ERROR: $MONGOVERSION"; exit 1; fi

## execute
echo $STATEMENTCREATEROLE | $MONGOC $MONGOOPT -quiet -host $HOSTNAME -port $PORT


