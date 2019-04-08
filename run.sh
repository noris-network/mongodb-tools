#!/usr/bin/env bash
#
# Version 0.6 beta
#
#   Role: readWriteSecure (spezifiziert durch $Kunde)
#
# Comments: IT WORKS FOR ME! SO SHIP IT! ;)
# bei Fehlern: jvetter hauen

## fix path from everywhere jaja pod/pushd
sPATH=$(dirname $0)

## GETOPTS
while getopts ":a:p:u:s:r:c:d:hP:C:R:A:" opt; do
  case $opt in
    a)
      #echo "-a $OPTARG"
      AUTHDB="$OPTARG"
      ;;
    p)
      #echo "-p $OPTARG"
      PORT="$OPTARG"
      ;;
    P)
      #echo "-P $OPTARG"
      mPRIVILEGES="$OPTARG"
      ;;
    C)
      #echo "-C $OPTARG"
      mCOLLECTION="$OPTARG"
      ;;
    R)
      #echo "-R $OPTARG"
      mSUBROLE="$OPTARG"
      ;;
    u)
      mUSER=$OPTARG
      ;;
    s)
      mPASS=$OPTARG
      ;;
    r)
      mROLE=$OPTARG
      ;;
    c)
      CREATIONMODE=$OPTARG
      ;;
    d)
      DATABASES=$OPTARG
      ;;
    A)
      AIO=$OPTARG
      ;;
    h)
      echo "Usage: $0 -a AUTHDB | -p PORT | -u mUSER | -s mPASS | -r mROLE | -c [ROLE|USER|LDAPUSER|CHANGEPASS|LISTUSER|LISTROLE|DROPUSER|DROPROLE|AUTHUPGRADE] | -d [db name|ALL]"
      echo
cat << EOF
# -a AUTHDB: creates user in this DB
# -p PORT: Mongod Port (def: 27017)
# -u mUSER: User der angelegt werden soll
# -s mPASS: Passwort, das verwendet werden soll (deprecated, now script reads pw from stdin)
# -r mROLE: Rolle, die dem User zugewiesen werden soll
# -c: CREATION MODE: ROLE|ROLECUSTOMADD|ROLECUSTOMUPDATEADD|ROLECUSTOMUPDATEDEL|USER|USERROLEADD|USERROLEDEL|LDAPUSER|CHANGEPASS|LISTUSER|LISTROLE|DROPUSER|DROPROLE|AUTHUPGRADE
# -d: Databasename or ALL (not everywhere supported, todo)
# -P: privileges for custom role (only used by ROLECUSTOMADD)
# -C: Collections (used for ROLE,ROLECUSTOMADD) [optional]
# -R: subroles (db.grantRolesToRole) [optional]
# -A: All in One (create user,role,db) [Quickstart, uses other functions from this sript]
#
# Examples:
#
# ROLE (built-in/template roles / role readWriteSecure specified in createrole.sh as template):
#       $0 -c ROLE -d ALL -r readWriteSecure
#       $0 -c ROLE -d testdb01 -r readWriteSecure
#
# ROLECUSTOMADD
#       $0 -c ROLECUSTOMADD -d ALL -r meineeigenerolle -P privilege1,privilege2,privilege3 -C collection1,collection2,collection3
#       $0 -c ROLECUSTOMADD -d testdb01 -r meineeigenerolle -P privilege1,privilege2,privilege3 -C collection1,collection2,collection3
#   -include subroles:
#       export mROLEINC='{ db:"test4", role: "read" }' $0 -c ROLECUSTOMADD -d testdb01 -r meineeigenerolle -P privilege1,privilege2,privilege3 -C collection1,collection2,collection3 -R read
#
# ROLECUSTOMUPDATEADD (Custom Rolle erweitern)
#       TODO db.grantRolesToRole()  db.grantPrivilegesToRole()
#
# ROLECUSTOMUPDATEDEL
#       TODO db.revokeRolesToRole()  db.revokePrivilegesToRole()
#
# USER:
#       $0 -c USER -d ALL -r readWriteSecure -a AuthDB -u testuser007 -s UserSecret01pass
#       $0 -c USER -d testdb01 -r readWriteSecure -a AuthDB -u testuser007
#
# USERROLEADD (User um Rolle fuer DB erweitern)
#       $0 -c USERROLEADD -d databasename -r readWriteSecure -a AuthDB -u testuser007
#
# USERROLEDEL (User eine Rolle fuer eine DB entziehen)
#       $0 -c USERROLEDEL -d databasename -r readWriteSecure -a AuthDB -u testuser007
#
# LDAPUSER:
#       $0 -c LDAPUSER -d ALL -r readWriteSecure -u testldapuser007
#       $0 -c LDAPUSER -d testdb01 -r readWriteSecure -u testldapuser007
#
# CHANGEPASS:
#       $0 -c CHANGEPASS -u testuser01 -a AuthDB             [-s update user password removed => now read pass from stdin]
#
# LISTUSER:
#       $0 -c LISTUSER               [list all users]
#       $0 -c LISTUSER -u testuser0  [list all users matching string testuser0]
#       $0 -c LISTUSER -a AuthDB     [list all users in AuthDB AuthDB]
#       $0 -c LISTUSER -a external   [list all external Users (LDAP/KERBEROS/SASL]
#
# LISTROLE:
#       $0 -c LISTROLE -d ALL        [list all roles in all databases]
#       $0 -c LISTROLE -d testdb03   [list all roles in db testdb03]
#
# DROPUSER:
#       $0 -c DROPUSER -a AuthDB -u testuser02              [drop user testuser02 from authdb AuthDB]
#       $0 -c DROPUSER  -u testldapuser007 -a external      [drop ldap user from mongodb]
#
# DROPROLE:
#       $0 -c DROPROLE -d testdb01 -r readWriteSecure
#
# AUTHUPGRADE:
#       $0 -c AUTHUPGRADE
#
# ------
# Specials:
#
# AIO:  [AllInOne: create Role in DB, create User with permissions for DB in AuthDB(-a)]
#       $0 -c AIO -A User#Role#DB1,DB2 -a AuthDB
#
EOF
      #echo "Example: bash ./run.sh -a AuthDB -p 27017 -u testuser01 -s spasswort -r readWriteSecure -c USER -d ALL"
      exit 255
      ;;
    \?)
      echo "Invalid option or no argument specified: -$OPTARG" >&2
      ;;
  esac
done

function defaults() {
  # set default mongodb port to 27017 if no other specified
  if [ -z $PORT ]; then
    >&2 echo "waring: using default port 27017";
    export PORT=27017
  fi

  # set default authdb to "AuthDB" - because we can
  if [ -z $AUTHDB ]; then
    >&2 echo "warning: setting default auth database to \"AuthDB\"";
    export AUTHDB="AuthDB"
  fi
}

function check_user() {
  if [ -z "$mUSER" ]; then echo "no username specified"; exit 1; fi
}

function check_pass() {
  if [ -z "$mPASS" ]; then
    echo -e "please specify user password:"
    read mPASS
  else
    echo "WARNING: password is compromised beacause specified on command line!"
    echo "ERROR: security fail!"
    exit 1
  fi
}

function check_role() {
  if [ -z "$mROLE" ]; then echo "no role specified"; exit 1; fi
}

function check_dbs() {
  if [ -z "$DATABASES" ]; then echo "no databases specified"; exit 1; fi
}

function check_privs() {
  if [ -z "$mPRIVILEGES" ]; then if [ -z "$mSUBROLE" ]; then echo "ERROR: neither privileges nor subroles specified (-P/-R) specified"; exit 1; fi; fi
}

# set default values
defaults

## GET DATABASES
if [ -f ~/.mongodbauth.js ]; then
  MONGOC='mongo --shell ~/.mongodbauth.js'
else
  MONGOC='mongo'
fi

## if no db specified, use all
if [ "$DATABASES" == "ALL" ]; then
  echo "using all DBs"
  DATABASES=$(echo 'show dbs' | $MONGOC -quiet -host $HOSTNAME -port $PORT | grep -v 'type "help" for help' | awk '{ print $1 }' | grep -v -E "(admin$|local$|${AUTHDB}$)")
fi

case "$CREATIONMODE" in
  "AIO")
    "$sPATH"/modules/aio.sh "${AIO}" "${AUTHDB}" "${PORT}"
    ;;
  "ROLE")
    check_role
    check_dbs
    ## CREATE ROLES IN EVERY DATABASE
    for db in ${DATABASES}; do
      echo "CREATE ROLE: DB=${db} DB=$PORT DB=$mROLE"
      ## takes three arguments, ARG1=DB ARG2=PORT ARG3=mROLE ARG4=collections todo
      "$sPATH"/modules/createrole.sh "${db}" "$PORT" "$mROLE" "${mCOLLECTION}"
    done
    ;;
  "ROLECUSTOMADD")
    check_role
    check_dbs
    check_privs
    ## CREATE ROLES IN EVERY DATABASE
    for db in ${DATABASES}; do
      echo "CREATE CUSTOM ROLE: DB=${db} PORT=$PORT ROLLE=$mROLE PRIVS=$mPRIVILEGES COLLS=${mCOLLECTION}" SUBROLE="${mSUBROLE}"
      ## takes six arguments, ARG1=DB ARG2=PORT ARG3=mROLE ARG4=mPRIVILEGES ARG5=mCOLLECTION and export mROLEINC as workaround to add advanced roles in a role :D
      "$sPATH"/modules/createrolecustom.sh "${db}" "$PORT" "$mROLE" "${mPRIVILEGES}" "${mCOLLECTION}" "${mSUBROLE}"
    done
    ;;
  "ROLECUSTOMUPDATEADD")
    check_role
    check_dbs
    check_privs
    ## CREATE ROLES IN EVERY DATABASE
    for db in ${DATABASES}; do
      echo "UPDATE CUSTOM ROLE(add privs): DB=${db} PORT=$PORT ROLLE=$mROLE PRIVS=$mPRIVILEGES COLLS=${mCOLLECTION}" SUBROLE="${mSUBROLE}"
      ## takes six arguments, ARG1=DB ARG2=PORT ARG3=mROLE ARG4=mPRIVILEGES ARG5=mCOLLECTION and export mROLEINC as workaround to add advanced roles in a role :D
      "$sPATH"/modules/updaterolecustomadd.sh "${db}" "$PORT" "$mROLE" "${mPRIVILEGES}" "${mCOLLECTION}" "${mSUBROLE}"
    done
    ;;
  "ROLECUSTOMUPDATEDEL")
    check_role
    check_dbs
    check_privs
    ## CREATE ROLES IN EVERY DATABASE
    for db in ${DATABASES}; do
      echo "UPDATE CUSTOM ROLE (revoke privs): DB=${db} PORT=$PORT ROLLE=$mROLE PRIVS=$mPRIVILEGES COLLS=${mCOLLECTION}" SUBROLE="${mSUBROLE}"
      ## takes six arguments, ARG1=DB ARG2=PORT ARG3=mROLE ARG4=mPRIVILEGES ARG5=mCOLLECTION and export mROLEINC as workaround to add advanced roles in a role :D
      "$sPATH"/modules/updaterolecustomdel.sh "${db}" "$PORT" "$mROLE" "${mPRIVILEGES}" "${mCOLLECTION}" "${mSUBROLE}"
    done
    ;;
  "USER")
    check_role
    check_dbs
    check_pass
    check_user
    ## CREATE USER IN AUTH DB
    db=$(tr -s ' ' '#' <<< $DATABASES)
    if [ -z $db ]; then echo "no DBs found"; exit 1; fi
    echo "CREATE USER: DB=${db} PORT=$PORT AUTHDB=$AUTHDB mUSER=$mUSER mPASS=$mPASS mROLE=$mROLE"
    ## takes six arguments, ARG1=DB ARG2=PORT ARG3=AUTHDB ARG4=mUSER ARG5=mPASS ARG6=mROLE
    "$sPATH"/modules/createuser.sh "${db}" "$PORT" "$AUTHDB" "$mUSER" "$mPASS" "$mROLE"
    ;;
  "LDAPUSER")
    check_role
    check_dbs
    check_user
    ## CREATE USER IN AUTH DB
    db=$(tr -s ' ' '#' <<< $DATABASES)
    if [ -z $db ]; then echo "no DBs found"; exit 1; fi
    echo "CREATE LDAPUSER: DB=${db} PORT=$PORT AUTHDB=$AUTHDB mUSER=$mUSER mROLE=$mROLE"
    ## takes five arguments, ARG1=DB ARG2=PORT ARG3=AUTHDB ARG4=mUSER ARG5=mROLE
    "$sPATH"/modules/createldapuser.sh "${db}" "$PORT" "$AUTHDB" "$mUSER" "$mROLE"
    ;;
  "CHANGEPASS")
    check_user
    check_pass
    ## CHANGE USER PASSWORD
    echo "UPDATE USER PASSWORD: PORT=$PORT AUTHDB=$AUTHDB mUSER=$mUSER mPASS=$mPASS"
    ## takes four arguments, ARG1=PORT ARG2=AUTHDB ARG3=mUSER ARG4=mPASS
    "$sPATH"/modules/changeuserpassword.sh "$PORT" "$AUTHDB" "$mUSER" "$mPASS"
    ;;
  "LISTUSER")
    ## derzeit wird nur die ausgabe von allen usern unterstuetzt, uebergebene argumente noch ohne nutzen
    #check_user
    "$sPATH"/modules/listusers.sh "$PORT" "$AUTHDB" "$mUSER"
    ;;
  "LISTROLE")
    ## derzeit wird nur die ausgabe von allen rollen unterstuetzt, uebergebene argumente noch ohne nutzen
    #check_user
    check_dbs
    db=$(tr -s ' ' '#' <<< $DATABASES)
    "$sPATH"/modules/listroles.sh "$PORT" "${db}" "$mROLE"
    ;;
  "DROPUSER")
    check_user
    "$sPATH"/modules/dropuser.sh "$PORT" "$AUTHDB" "$mUSER"
    ;;
  "DROPROLE")
    check_role
    check_dbs
    db=$(tr -s ' ' '#' <<< $DATABASES)
    "$sPATH"/modules/droprole.sh "$PORT" "${db}" "$mROLE"
    ;;
  "AUTHUPGRADE")
    "$sPATH"/modules/authupdatecramtoscramsha1.sh "$PORT"
    ;;
  "USERROLEADD")
    check_role
    check_dbs
    check_user
    ## CREATE USER IN AUTH DB
    db=$(tr -s ' ' '#' <<< $DATABASES)
    if [ -z $db ]; then echo "no DBs found"; exit 1; fi
    echo "ADDING ROLE TO USER: DB=${db} PORT=$PORT AUTHDB=$AUTHDB mUSER=$mUSER mROLE=$mROLE"
    ## takes six arguments, ARG1=DB ARG2=PORT ARG3=AUTHDB ARG4=mUSER ARG5=mPASS ARG6=mROLE
    "$sPATH"/modules/updateuserrolesadd.sh "${db}" "$PORT" "$AUTHDB" "$mUSER" "$mROLE"
    ;;
  "USERROLEDEL")
    ;;
  *)
    echo "ERROR: invalid option -c $OPTARG"
    exit 255
    ;;
esac

