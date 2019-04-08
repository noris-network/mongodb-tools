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

case "$AUTHDB" in
  "external"|"LDAP")
    STATEMENT='db = db.getSiblingDB('\"\$external\"'); db.dropUser('\"$mUSER\"', {w: "majority", wtimeout: 5000}) '
    ;;
  *)
    STATEMENT='db = db.getSiblingDB('\"$AUTHDB\"'); db.dropUser('\"$mUSER\"', {w: "majority", wtimeout: 5000})'
    ;;
esac

echo "$STATEMENT" | $MONGOC $MONGOOPT -quiet -host $HOSTNAME -port $PORT

