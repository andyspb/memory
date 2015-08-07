#!/bin/bash

SCRIPT=`realpath $0`
SCRIPTPATH=`dirname $SCRIPT`

VERBOSE=1

APP1="com.palm.app.clock"
APP2="com.palm.app.settings"
APP3="com.palm.app.enyo2sampler"
APP4="com.palm.app.facebook2"
APP5="com.palm.app.photos"


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

function lunchApp() {
        local APP=${1}
        local sleep_time=180
        echo Launch $APP ...
        RESULT=$(luna-send -n 1 palm://com.palm.applicationManager/launch "{\"id\":\"${APP}\"}")
        PROCESSID=$(echo $RESULT | awk -F\" '{print $(NF-1)}')
        echo $RESULT
        echo "Sleep " ${sleep_time} " secs ..."
        sleep ${sleep_time}
        record 1_after_launched
}

function closeApp() {
	local APP=${1}
        local sleep_time=10
	echo "Closing " ${APP}
        echo "luna-send -n 1 palm://com.palm.applicationManager/closeByAppId '{\"id\":\"${APP}\"}'"
        luna-send -n 1 palm://com.palm.applicationManager/closeByAppId "{\"id\":\"${APP}\"}"
        echo "Sleep " ${sleep_time} " secs ..."
        sleep ${sleep_time}
        record 2_after_closed
}

# NOTE: Put below line in /etc/event.d/WebAppMgr-compositor before launching WebAppMgr 
# echo 1 > /proc/pvr/memory_utilization
# drop cashes
echo 3 > /proc/sys/vm/drop_caches
 

cat /proc/stat > stat
record 0_before_start
# ${SCRIPTPATH}/measure_mem_state.sh
lunchApp ${APP1}
lunchApp ${APP2}
lunchApp ${APP3}
lunchApp ${APP4}
lunchApp ${APP5}

# ${SCRIPTPATH}/measure_mem_state.sh
echo Sleep 180 secs ...
sleep 180

closeApp ${APP5}
closeApp ${APP4}
closeApp ${APP3}
closeApp ${APP2}
closeApp ${APP1}

# ${SCRIPTPATH}/measure_mem_state.sh
echo Sleep 180 secs ...
sleep 180
echo 3 > /proc/sys/vm/drop_caches | cat /proc/meminfo | grep MemFree
echo Sleep 180 secs ...
sleep 180
echo 3 > /proc/sys/vm/drop_caches | cat /proc/meminfo | grep MemFree
echo "Done :-D"
