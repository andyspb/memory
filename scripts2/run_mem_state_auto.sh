#!/bin/bash

SCRIPT=`realpath $0`
SCRIPTPATH=`dirname $SCRIPT`

VERBOSE=1
APP="com.palm.app.bareapp"

function record() {
    if [ -z "$1" ]; then
        echo Tag not specified. $1
        return 0
    fi
    TAG="$1"
    if [ ! -z $VERBOSE ]; then
        PID_WAM=$(pgrep WebAppMgr)
        PID_QTT=$(pgrep QtWebProcess)

        # echo Record $TAG ...
        dmesg | grep '@@' > dmesg.${TAG}
        ${SCRIPTPATH}/measure_mem_state.sh dmesg.${TAG}
        grep '####' /home/root/WAM.log > WAM.log.${TAG}
        ps aux | grep 'WebAppMgr\|QtWebProcess' > ps.${TAG}
        if [ ! -z $PID_WAM ]; then
            ${SCRIPTPATH}/find_pss.sh $PID_WAM > Pss.${TAG}.WebAppMgr
            cat /proc/${PID_WAM}/smaps > smaps.${TAG}.WebAppMgr
        fi
        if [ ! -z $PID_QTT ]; then
            ${SCRIPTPATH}/find_pss.sh ${PID_QTT} > Pss.${TAG}.QtWebProcess
            cat /proc/${PID_QTT}/smaps > smaps.${TAG}.QtWebProcess
        fi
        echo 3 > /proc/sys/vm/drop_caches
        cat /proc/meminfo > meminfo.${TAG}
    fi
}

# NOTE: Put below line in /etc/event.d/WebAppMgr-compositor before launching WebAppMgr 
# echo 1 > /proc/pvr/memory_utilization

cat /proc/stat > stat
record 0_before_start
# ${SCRIPTPATH}/measure_mem_state.sh
echo Launch $APP ...
RESULT=$(luna-send -n 1 palm://com.palm.applicationManager/launch "{\"id\":\"${APP}\"}")
PROCESSID=$(echo $RESULT | awk -F\" '{print $(NF-1)}')
echo $RESULT
echo Sleep 6 secs ...
sleep 6
record 1_after_launched
# ${SCRIPTPATH}/measure_mem_state.sh
echo Sleep 6 secs ...
sleep 6
echo Close $PROCESSID
echo luna-send -n 1 palm://com.palm.applicationManager/close "{\"processId\":\"$PROCESSID\"}"
luna-send -n 1 palm://com.palm.applicationManager/close "{\"processId\":\"$PROCESSID\"}"
record 2_after_closed
# ${SCRIPTPATH}/measure_mem_state.sh

echo Done :-D
