#!/bin/bash

SCRIPT=`realpath $0`
SCRIPTPATH=`dirname $SCRIPT`
PROC_QTW="QtWebProcess"
PROC_WAM="WebAppMgr"
PROC_SFM="surface-manager"
VERBOSE=1
#APP="com.palm.app.bareapp"
APP="com.palm.app.baremoon2"
FREE_MEM=0

function record() 
{
    if [ -z "$1" ]; then
        echo Tag not specified. $1
        return 0
    fi
    TAG="$1"
    if [ ! -z $VERBOSE ]; then
        PID_WAM=$(pgrep WebAppMgr)
        PID_QTT=$(pgrep QtWebProcess)
        echo Record $TAG ...
        dmesg | grep '@@' > dmesg.${TAG}
        echo 3 > /proc/sys/vm/drop_caches
        cat /proc/meminfo > meminfo.${TAG}
        echo --------------------------------------------------------------------------------------------------------------
        head -4 meminfo.${TAG}
        echo --------------------------------------------------------------------------------------------------------------
        FREE_MEM=$(cat meminfo.${TAG} | awk '/MemFree:/ {mem_free = $2} END { print mem_free}')
                                               
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
    fi
}

function tracePss() 
{
    local PID=$(pgrep ${1})
    if [ ! -z $PID ]; then
    	local PROC_FILE="/proc/${PID}/smaps"
    	for item in Pss
    	do
            printf "====== %20s %10s ==========================\n" ${1} ${item}
            cat $PROC_FILE | awk -v item=${item} 'NF > 3 { f = $NF } $1 ~ /^'${item}:'/ && f ~ /(\/|\[)/ { printf "%-70s %6d K\n", f, $2 } ' | sort -nr -k2,2 | head -${LIMIT}
        done
    fi
}

# NOTE: Put below line in /etc/event.d/WebAppMgr-compositor before launching WebAppMgr 
# echo 1 > /proc/pvr/memory_utilization
# drop cashes 
echo 3 > /proc/sys/vm/drop_caches
cat /proc/stat > stat
record 0_before_start 
MEM_FREE_BEFORE_START=$FREE_MEM 
tracePss $PROC_QTW                                                                                                 
tracePss $PROC_WAM                                                                                                 
tracePss $PROC_SFM
# ${SCRIPTPATH}/measure_mem_state.sh
echo Launch $APP ...
RESULT=$(luna-send -n 1 palm://com.palm.applicationManager/launch "{\"id\":\"${APP}\"}")
PROCESSID=$(echo $RESULT | awk -F\" '{print $(NF-1)}')
echo $RESULT
echo Sleep 120 secs ...
sleep 120
record 1_after_launched
MEM_FREE_AFTER_LAUNCH=$FREE_MEM
tracePss $PROC_QTW                                                                                                 
tracePss $PROC_WAM                                                                                                 
tracePss $PROC_SFM
# ${SCRIPTPATH}/measure_mem_state.sh
echo Sleep 5 secs ...
sleep 5
echo Close $PROCESSID
echo luna-send -n 1 palm://com.palm.applicationManager/close "{\"processId\":\"$PROCESSID\"}"
luna-send -n 1 palm://com.palm.applicationManager/close "{\"processId\":\"$PROCESSID\"}"
echo Sleep 5 secs ...
sleep 5
record 2_after_closed 
MEM_FREE_AFTER_CLOSE=$FREE_MEM
tracePss $PROC_QTW
tracePss $PROC_WAM
tracePss $PROC_SFM 
echo Sleep 180 sec ...
sleep 180
record 3_after_closed_sleep 
MEM_FREE_AFTER_CLOSE_WAIT=$FREE_MEM
tracePss $PROC_QTW
tracePss $PROC_WAM
tracePss $PROC_SFM
# ${SCRIPTPATH}/measure_mem_state.sh
echo --------------------------------------------------------------------------------------------------------------
printf "Free Mem analysis:\n"
#echo $MEM_FREE_BEFORE_START " " $MEM_FREE_AFTER_LAUNCH " " $MEM_FREE_AFTER_CLOSE " " $MEM_FREE_AFTER_CLOSE_WAIT
printf "1. Before app launch:        %d kB\n" $MEM_FREE_BEFORE_START 
printf "2. After app started:        %d kB\n" $MEM_FREE_AFTER_LAUNCH 
printf "3. After app closed:         %d kB\n" $MEM_FREE_AFTER_CLOSE
printf "4. After app closed + 3 min: %d kB\n" $MEM_FREE_AFTER_CLOSE_WAIT

bl=$(($MEM_FREE_BEFORE_START - $MEM_FREE_AFTER_LAUNCH))
printf "Free Mem consumprion (1)-(2) %d\n" $bl
lc=$(($MEM_FREE_AFTER_LAUNCH - $MEM_FREE_AFTER_CLOSE_WAIT))
printf "Free Mem consumption (2)-(4) %d\n" $lc
bc=$(($MEM_FREE_BEFORE_START - $MEM_FREE_AFTER_CLOSE_WAIT))
printf "Free Mem consumption (1)-(4) %d\n" $bc                                                                        
                                                                           

 
echo Done :-D
