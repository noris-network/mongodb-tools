#!/usr/bin/env bash

#set -x

aioALLARGS="$1"
aioPARENT_CMD="$(ps -o comm= $PPID)"
## wuergaround
if [ "${aioPARENT_CMD}" == "bash" ]; then aioPARENT_CMD="run.sh"; fi
aioMODULEPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
aioBASEPATH=${aioMODULEPATH%modules}
aioPARENTSCRIPT="${aioBASEPATH}/${aioPARENT_CMD}"
aioLOGFILE="/tmp/.bashmymongo.aio.$(date +%s).$$.log"
aioRC=0
aioUSERRC=0

## seperate params
aioUSER=$(awk -F'#' '{print $1}' <<< $aioALLARGS)
aioROLE=$(awk -F'#' '{print $2}' <<< $aioALLARGS)
aioSCHEMATA=$(awk -F'#' '{print $3}' <<< $aioALLARGS)
aioAUTHDB="$2"
aioPORT="$3"


## seperate arguments from params
if [ -z "${aioROLE}" ]; then aioROLE="readWriteSecure"; fi
if [ -z "${aioSCHEMATA}" ]; then aioSCHEMATA="${aioUSER}"; fi
## aioAUTHDB: default wird per AUTHDB von run.sh auf AuthDB (def: admin) gesetzt
if [ -z "${aioAUTHDB}" ]; then aioAUTHDB="admin"; fi
if [ -z "${aioPORT}" ]; then aioPORT=27017; fi

##needed functions http://www.howtogeek.com/howto/30184/10-ways-to-generate-a-random-password-from-the-command-line/
randpw(){ < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32};echo;}

## do things
ycounter=0
IFS=","

#echo "Doing All in One"
#set -x

for aiodb in ${aioSCHEMATA}
do
  aiotmppw=$(randpw)
  &>$aioLOGFILE  "${aioPARENTSCRIPT}" -c ROLE -d "${aiodb}" -r "${aioROLE}" -p "${aioPORT}"

  ## check if role exists
  >&2 echo -n "check if role was created: "
  >&2 "${aioMODULEPATH}"/checkusernroles.sh -d "${aiodb}" -r "${aioROLE}" -p "${aioPORT}" -a "${aioAUTHDB}"
  if [ $? != 0 ]; then aioRC=2;>&2 echo "ERROR"; else >&2 echo "SUCCESS";fi

  if [ "${ycounter}" == 0 ]; then
    ## check if user already exists
    >&2 "${aioMODULEPATH}"/checkusernroles.sh -p "${aioPORT}" -u "${aioUSER}" -a "${aioAUTHDB}"
    if [ $? == 0 ]; then aioRC=1; aioUSERRC=2; >&2 echo "WARNING: not setting password or modifying user because user ${aioUSER} already exists" ;fi

    ## create user
    &>>$aioLOGFILE "${aioPARENTSCRIPT}" -c USER -d "${aiodb}" -r "${aioROLE}" -a "${aioAUTHDB}" -u "${aioUSER}" -p "${aioPORT}" <<< ${aiotmppw}
    ## check if users exists
    if [ "$aioUSERRC" != 2 ]; then
      >&2 echo -n "check if user was created: "
      >&2 "${aioMODULEPATH}"/checkusernroles.sh -p "${aioPORT}" -u "${aioUSER}" -a "${aioAUTHDB}"
      if [ $? != 0 ]; then aioRC=2; >&2 echo "ERROR"; else >&2 echo "SUCCESS"; fi
    fi

    ## check if user and role in specified db exists
    >&2 echo -n "check if user and role in specific db was created: "
    >&2 "${aioMODULEPATH}"/checkusernroles.sh -p "${aioPORT}" -u "${aioUSER}" -d "${aiodb}" -r "${aioROLE}" -a "${aioAUTHDB}"
    if [ $? != 0 ]; then aioRC=2; >&2 echo "ERROR"; else >&2 echo "SUCCESS"; fi

    let ycounter+=1
    #echo ${aiotmppw}
  else
    ## und danach ein update
    &>>$aioLOGFILE "${aioPARENTSCRIPT}" -c USERROLEADD -d "${aiodb}" -r "${aioROLE}" -a "${aioAUTHDB}" -u "${aioUSER}" -p "${aioPORT}"

    ## check if user and role in specified db exists
    >&2 echo -n "check if user and role in specific db was created: "
    >&2 "${aioMODULEPATH}"/checkusernroles.sh -p "${aioPORT}" -u "${aioUSER}" -d "${aiodb}" -r "${aioROLE}" -a "${aioAUTHDB}"
    if [ $? != 0 ]; then aioRC=2; >&2 echo "ERROR"; else >&2 echo "SUCCESS"; fi
  fi
  if [ "${aioUSERRC}" == 0 ]; then echo "${aiotmppw}"; fi
done

unset IFS


## debug
#echo "DEBUG: 1:$aioUSER 2:$aioROLE 3:$aioSCHEMATA Parent:$aioPARENT_CMD Base:$aioBASEPATH PScript:$aioPARENTSCRIPT"

if [ "${aioRC}" != 0 ]; then >&2 echo "WARNINGS OR ERRORS occured!"; fi
exit ${aioRC}

