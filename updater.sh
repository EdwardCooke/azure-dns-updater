#!/bin/bash

while getopts a:h:p:s:t:u:z: option
do
    case $option
    in
        a) APPID=${OPTARG};;
        h) HOSTS=${OPTARG};;
        p) PASS=${OPTARG};;
        r) RG=${OPTARG};;
        s) SUBID=${OPTARG};;
        t) TENANT=${OPTARG};;
        u) GETIPURL=${OPTARG};;
        z) ZONE=${OPTARG};;
    esac
done

if [ -z $APPID ]
then
    SHOWHELP=1
fi

if [ -z $HOSTS ]
then
    SHOWHELP=1
fi

if [ -z $PASS ]
then
    SHOWHELP=1
fi

if [ -z $RG ]
then
    SHOWHELP=1
fi

if [ -z $SUBID ]
then
    SHOWHELP=1
fi

if [ -z $TENANT ]
then
    SHOWHELP=1
fi

if [ -z $GETIPURL ]
then
    SHOWHELP=1
fi

if [ -z $ZONE ]
then
    SHOWHELP=1
fi

if [ "$SHOWHELP" == "1" ]
then
    echo "Usage -a <APPID> -h <HOSTS> -p <PASS> -r <RG> -s <SUBID> -t <TENANT> -u <GETIPURL> -z <ZONE>"
    echo ""
    echo "Any parameter can be excluded if the appropriate (in <>) environment variables are set"
    echo "APPID: ${APPID}"
    echo "HOSTS: ${HOSTS}"
    echo "PASS: ${PASS}"
    echo "RG: ${RG}"
    echo "SUBID: ${SUBID}"
    echo "TENANT: ${TENANT}"
    echo "GETIPURL: ${GETIPURL}"
    echo "ZONE: ${ZONE}"

    exit -1
fi

MYIP=$(curl $GETIPURL)
R=$(curl -X POST -d "grant_type=client_credentials&client_id=$APPID&client_secret=$PASS&resource=https%3A%2F%2Fmanagement.azure.com%2F" https://login.microsoftonline.com/$TENANT/oauth2/token)
TOKEN=$(echo $R | jq ".access_token" -r)

readarray -d , -t HOSTSPLIT <<<"$HOSTS"

for HOST in ${HOSTSPLIT[@]}
do  
    #HOST=${HOSTSPLIT[n]}

    if [ "$HOST" == "@" ]
    then
        unset HOST
    fi

    if [ ! -z $HOST ]
    then
        FQDN="$HOST.$ZONE."
    else
        FQDN="$ZONE."
    fi
    
    echo "Updating $FQDN"

    BODY=$(cat <<EOF
{
            "properties": {
                "fqdn": "$FQDN",
                "TTL": 60,
                "ARecords": [
                    {
                        "ipv4Address": "$MYIP"
                    }
                ],
                "targetResource": {},
                "provisioningState": "Succeeded"
            }
}
EOF
)

    if [ -z $HOST ]
    then
        HOST="@"
    fi

    curl -d "$BODY" -X PUT -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" https://management.azure.com/subscriptions/$SUBID/resourceGroups/$RG/providers/Microsoft.Network/dnsZones/$ZONE/A/$HOST?api-version=2018-05-01
    echo "Updated"
done