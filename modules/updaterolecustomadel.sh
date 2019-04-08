#!/usr/bin/env bash
# creates roles per database! https://docs.mongodb.org/manual/tutorial/manage-users-and-roles/#create-a-user-defined-role
# ToDo: add dynamic permissions through script option

echo not yet
exit 255

## gets arguments from run.sh
db=$1
PORT=$2
mROLE=$3
mPRIV=$4
mCOLL=$5
if [ -z "${mROLEINC}" ]; then mROLEINC=$6; fi


MONGOC="/usr/bin/mongo"

## detect auth
if [ -f ~/.mongodbauth.js ]; then
  MONGOOPT='--shell /root/.mongodbauth.js'
else
  MONGOOPT=''
fi

if [ -n "$mPRIV" ]; then
  IFS=$','
  for p in ${mPRIV}
  do
    schnitzel=${schnitzel}\'${p}\',
  done
  unset IFS
else
  schnitzel=''
fi

if [ -n "$mCOLL" ]; then
  IFS=$','
  for c in ${mCOLL}
  do
    kortelett=${kortelett}"{ resource: { db: '$db', collection: '$c' },actions: [ ${schnitzel} ] },"
  done
  unset IFS
else
  kortelett="{ resource: { db: '$db', collection: '' },actions: [ ${schnitzel} ] }"
fi

echo $kortelett
#exit 255

STATEMENTCREATEROLE="db = db.getSiblingDB('$db'); \
  db.createRole( \
    { role: '$mROLE', privileges: [ ${kortelett} ], roles: [ ${mROLEINC} ] } \
  )"


## execute
echo $STATEMENTCREATEROLE | $MONGOC $MONGOOPT -quiet -host $HOSTNAME -port $PORT
mRC=$?

## exit with mongo client exit code
if [ "${mRC}" != 0 ]; then echo "ERROR: cannot create role:$mROLE privs:$mPRIV colls:$mCOLL"; exit ${mRC}; fi

