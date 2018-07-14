#!/bin/bash

MSG=""

SCRIPT_DIR="`echo "$0" | rev | cut -d/ -f2- | rev`/"
DOMS_FILE=$SCRIPT_DIR"doms"

if [ -f $DOMS_FILE ]; then
    DOMS=$(cat $DOMS_FILE)
else
    echo "file doms doesn't exist, create a file named doms with domain names, 1 domain per line"
    echo "i.e: file doms: "
    echo "dom1.com"
    echo "dom2.com"
    echo "dometc.com"
    exit 1
fi

for DOM in $DOMS; do 
    echo "checking $DOM"
    EXPDATE=`date --date="$(echo | openssl s_client  -connect $DOM:443 2>/dev/null | openssl x509 -noout -issuer -subject -dates | grep -i notbefore | cut -d = -f 2)" --iso-8601`
    CURDATE=`date --iso-8601`

    DATEDIFF="$(( ($(date -d "$EXPDATE" '+%s') - $(date -d "$CURDATE" '+%s'))/60/60/24))"

    DIFFLIMIT=15

    if [ $DATEDIFF -lt $DIFFLIMIT ]; then 
        MSG="$MSG for $DOM diff: $DATEDIFF is lower than $DIFFLIMIT  days \n"
        MSG="$MSG curdate:  $CURDATE \n"
        MSG="$MSG EXPDATE:  $EXPDATE \n"
        MSG="$MSG ---------------------------------------- \n \n"
    fi
    echo "checked $DOM"
done

if [ ! -z "$MSG" ]; then
    zenity --error --text="$MSG"
else
    echo "all sites expires after more than $DIFFLIMIT days"
fi 

echo "certbot renew will fix it on server"
