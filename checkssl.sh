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
    DOM_CERT=$(echo openssl s_client  -connect $DOM:443 2>/dev/null)
    EXPDATE=`date --date="$(echo | $DOM_CERT 2>/dev/null | openssl x509 -noout -issuer -subject -dates 2>/dev/null | grep -i notafter | cut -d = -f 2)" --iso-8601`
    CURDATE=`date --iso-8601`
    
    DOM_CN=$(echo | $DOM_CERT 2>/dev/null | openssl x509 -noout -subject 2>/dev/null | cut -d \= -f 3)

    DATEDIFF="$(( ($(date -d "$EXPDATE" '+%s') - $(date -d "$CURDATE" '+%s'))/60/60/24))"
    DIFFLIMIT=15
    ALTERNATIVE_DOMS=`echo | $DOM_CERT 2>/dev/null | openssl x509 -noout -text | grep "Subject Alternative Name" -A2 | grep -Eo "DNS:[a-zA-Z 0-9.*-]*" |  sed "s/DNS://g"`

    VALID=false
    for i in $ALTERNATIVE_DOMS; do
        if [ "$i" == "$DOM" ]; then
            VALID=true
        fi
    done

    NO_WWW_DOM=`echo $DOM_CN | sed s/www.//`
    NO_WWW_CN=`echo $NO_WWW_CN | sed s/www.//`

    if [ "$DOM_CN" == "$DOM" ] || [ "$NO_WWW_DOM" == "$NO_WWW_CN" ]; then
        VALID=true
    fi 

    echo " exp $EXPDATE cur $CURDATE diff $DATEDIFF"

    if [ $DATEDIFF -lt $DIFFLIMIT ]; then 
        MSG="$MSG for $DOM diff: $DATEDIFF is lower than $DIFFLIMIT  days \n"
        MSG="$MSG curdate:  $CURDATE \n"
        MSG="$MSG EXPDATE:  $EXPDATE \n"
        MSG="$MSG ---------------------------------------- \n \n"
    fi
    
    if [ $VALID == false ]; then
        MSG="$MSG for $DOM Certificate invalid for this domain \n"
        TXT_CERT=`echo | $DOM_CERT` 
    fi
    echo "checked $DOM"
done

if [ ! -z "$MSG" ]; then
    zenity --error --text="$MSG"
else
    echo "all sites expires after more than $DIFFLIMIT days"
fi 

echo "certbot renew will fix it on server"
