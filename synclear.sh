#!/bin/bash

DST_PORT=2049
WAIT_TIME=5
CHECK_TIME=10
MAX_DIFF=$( expr $WAIT_TIME - 1  )

CheckConnEntry() {
    local ID="$1"
    echo checking ${ID}

    #Refetch, because the last while loop might have waited
    local OTIME=$( conntrack -L -p tcp --orig-port-dst=${DST_PORT} --state SYN_SENT -o extended,id 2>/dev/null | grep $ID | awk '{print $5}')
    #waiting to see if connection connects, or if the timer decrments over WAIT_TIME.
    sleep ${WAIT_TIME}
    local NTIME=$( conntrack -L -p tcp --orig-port-dst=${DST_PORT} --state SYN_SENT -o extended,id 2>/dev/null | grep $ID | awk '{print $5}')
    if [[ -z $NTIME || -z $OTIME ]]
    then
        echo $ID Changed state.
        continue; #Dont check timers 
    fi

    #echo OTIME: ${OTIME} NTIME: ${NTIME} MAX_DIFF ${MAX_DIFF}

    if [ $( expr $OTIME - $MAX_DIFF  ) -lt $NTIME ]
    then
        echo Remove $ID
        #SYN_SENT src=10.129.0.1 dst=172.30.90.133 sport=9999 dport=2049
        local ENTRY="$(conntrack -L -p tcp --orig-port-dst=${DST_PORT} --state SYN_SENT -o extended,id 2>/dev/null| grep $ID)"
        MATCH="--orig-src $( egrep -o 'src=[0-9\.]+' <<<$ENTRY | head -n1 | cut -d= -f2 )"
        MATCH="$MATCH --orig-dst $( egrep -o 'dst=[0-9\.]+' <<<$ENTRY | head -n1 | cut -d= -f2 )"
        MATCH="$MATCH --orig-port-src $( egrep -o 'sport=[0-9]+' <<<$ENTRY | head -n1 | cut -d= -f2 )"
        set -x
        conntrack -D -p tcp  --orig-port-dst=${DST_PORT} --state SYN_SENT $MATCH
        set +x
    fi
}



while true;
do 

    #List all SYN_SENT + dst=src match aka no nat. with the port DST_PORT.
    conntrack -L -p tcp --orig-port-dst=${DST_PORT} --state SYN_SENT -o extended,id | grep -P 'dst=([^ ]+).* \[UNREPLIED\] src=(\1)' | egrep -o 'id=[0-9]+' |\
    while read CON 
    do 
        CheckConnEntry $CON &
        echo $! 
    done

    #Could add -E here and remove full outer loop

sleep ${CHECK_TIME};
done
