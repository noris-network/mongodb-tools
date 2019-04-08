#!/usr/bin/env bash
#
# check user or role present
# because fuck you mongo shell

MONGOC="/usr/bin/mongo"
checkRC=0

## always exit code 0 on role check for existing roles
declare -a builtinroles="read readWrite  dbAdmin  dbOwner  userAdmin  clusterAdmin  clusterManager  clusterMonitor  hostManager  backup  restore  readAnyDatabase  readWriteAnyDatabase  userAdminAnyDatabase  dbAdminAnyDatabase  root  __system"

## detect auth
if [ -f ~/.mongodbauth.js ]; then
  MONGOOPT='--shell /root/.mongodbauth.js'
else
  MONGOOPT=''
fi

## GETOPTS
while getopts ":u:p:a:r:d:h" opt; do
  case $opt in
    u)
      checkUSER="$OPTARG"
      ;;
    r)
      checkROLE="$OPTARG"
      ;;
    d)
      checkDB="$OPTARG"
      ;;
    p)
      checkPORT="$OPTARG"
      ;;
    a)
      checkAUTHDB="$OPTARG"
      ;;
    h)
      ##help
      echo "Usage: (check if user and/or role exists)"
      echo "  $0 -u USER -r ROLE -d SCHEMA (optional) -p MongoDBport"
      echo "  $0 -u USER -r ROLE -d SCHEMA (optional) -p MongoDBport"
      echo
      ;;
    *)
      #nothing
      :
      ;;
  esac
done

## default authdb
if [ -z "$checkAUTHDB" ]; then
  checkAUTHDB="admin"
fi

## check for existing user
if [ -n "${checkUSER}" -a -z "${checkROLE}" ]; then 
  STATEMENTCREATEUSER="db = db.getSiblingDB('admin'); db.system.users.find({ user: \"$checkUSER\", });"
  echo "$STATEMENTCREATEUSER" | $MONGOC $MONGOOPT -quiet -host $HOSTNAME -port $checkPORT | grep -e "${checkUSER}" | grep -e "${checkAUTHDB}" 
  if [ $? != 0 ]; then checkRC=2; fi
fi

## check for existing role
if [ -n "${checkROLE}" -a -n "${checkDB}" -a -z "${checkUSER}" ]; then
  if [[ ! ${builtinroles[*]} =~ "${checkROLE}" ]]; then
    STATEMENTCREATEUSER="db = db.getSiblingDB('admin'); db.system.roles.find({ role: \"$checkROLE\", });"
    echo "$STATEMENTCREATEUSER" | $MONGOC $MONGOOPT -quiet -host $HOSTNAME -port $checkPORT | grep -e "${checkROLE}" | grep -e "${checkDB}" 
    if [ $? != 0 ]; then checkRC=2; fi
  else
    :
  fi
fi

## check for existing user/role
if [ -n "${checkROLE}" -a -n "${checkDB}" -a -n "${checkUSER}" ]; then
  STATEMENTCREATEUSER="db = db.getSiblingDB('admin'); db.system.users.find({ user: \"$checkUSER\", });"
  echo "$STATEMENTCREATEUSER" | $MONGOC $MONGOOPT -quiet -host $HOSTNAME -port $checkPORT | grep -e "${checkUSER}" | grep -e "${checkAUTHDB}" | grep -e "${checkROLE}" | grep -e "${checkDB}" 
  if [ $? != 0 ]; then checkRC=2; fi
fi

#STATEMENTCREATEUSER="db = db.getSiblingDB('admin'); \
#db.system.roles.find({ roles: \"$mROLE\", }); \
#db.system.users.find({ user: \"$mUSER\", }); \
#"
#echo "$STATEMENTCREATEUSER" | $MONGOC $MONGOOPT -quiet -host $HOSTNAME -port $PORT



exit ${checkRC}


