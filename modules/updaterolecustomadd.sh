#!/usr/bin/env bash
# creates roles per database! https://docs.mongodb.org/manual/tutorial/manage-users-and-roles/#create-a-user-defined-role
# ToDo: add dynamic permissions through script option

#echo not yet
#exit 255

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

## multiple privileges
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

## multiple collections
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


## Update Privileges from Role
if [ -n "${schnitzel}" ]; then
  echo "Update Role Privileges: $kortelett"
  ## STATEMENT db.grantPrivilegesToRole()
  STATEMENTGRANTP="db = db.getSiblingDB('$db'); \
    db.grantPrivilegesToRole( \"${mROLE}\", \
      [ ${kortelett} ], { w: 'majority' } \
    )"

  echo $STATEMENTGRANTP | $MONGOC $MONGOOPT -quiet -host $HOSTNAME -port $PORT
  if [ $? != 0 ]; then mRC=1; echo "ERROR: (grantPrivilegesToRole) cannot update role:$mROLE privs:$mPRIV colls:$mCOLL"; fi
fi

## Update Role with Subroles
if [ -n "${mROLEINC}" ]; then
  echo "Update Role with Subroles: ${mROLEINC}"
  ## STATEMENT db.grantRolesToRole()
  STATEMENTGRANTR="db = db.getSiblingDB('$db'); \
    db.grantRolesToRole( \"${mROLE}\", \
      [ \"${mROLEINC}\" ], { w: 'majority' } \
    )"

  echo $STATEMENTGRANTR | $MONGOC $MONGOOPT -quiet -host $HOSTNAME -port $PORT
  if [ $? != 0 ]; then mRC=1; echo "ERROR: (grantRolesToRole) cannot update role:$mROLE privs:$mPRIV colls:$mCOLL"; fi
fi

exit ${mRC}
