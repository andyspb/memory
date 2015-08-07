#!/bin/bash

# Wait until we're idle.

SCRIPT=`realpath $0`
SCRIPTPATH=`dirname $SCRIPT`

DMESG_FILE="$1"

function get_pss()
{
    local __resultvar=$1
    local __proc_file="/proc/$2/smaps"

    local __pss=$(cat $__proc_file | awk '/Pss:/ {sum += $2} END { print sum }')
    eval $__resultvar="'$__pss'"
}

function get_pvr_mem()
{
    local __resultvar=$1
    local __dmesg_file=$2
    local __pid=$3

    local __pvr_mem=$(grep '@@' $__dmesg_file | grep "pid\[${__pid}\]" | awk 'BEGIN { mem=0 } /ALLOC/ { mem += substr($7, 2, length($7)) } /FREE/ { mem -= substr($7, 2, length($7)) } END { print mem/1024.0 }')
    eval $__resultvar="'$__pvr_mem'"
}

# function get_proc_meminfo()
# {
#     local __resultvar=$1
#     local __meminfo_file="/proc/meminfo"

#     local __freemem=$(cat $__meminfo_file | awk '/MemFree:/ { sum += $2 } /Buffers:/ { sum += $2 } /Cached:/ { sum += $2 } END { print sum }')
#     eval $__resultvar="'$__freemem'"
# }

# get_proc_meminfo FREEMEM
# printf "%s %10d\n" "MemFree + Buffers + Cached" $FREEMEM
echo ----------------------------------------------------------------------
head -4 /proc/meminfo
echo ----------------------------------------------------------------------
printf "%20s %10s %10s\n" "Process Name" "PSS" "PVR_MEM"
echo ======================================================================
PSS_QTT=0
PSS_WAM=0
PSS_SFM=0
PVRMEM_QTT=0
PVRMEM_WAM=0
PVRMEM_SFM=0

PID_QTT=$(pgrep QtWebProcess)
if [ ! -z $PID_QTT ]; then
    get_pss PSS_QTT $PID_QTT
    get_pvr_mem PVRMEM_QTT $DMESG_FILE $PID_QTT
    printf "%20s %10d %10d\n" "QtWebProcess" $PSS_QTT $PVRMEM_QTT
fi

PID_WAM=$(pgrep WebAppMgr)
if [ ! -z $PID_WAM ]; then
    get_pss PSS_WAM $PID_WAM
    get_pvr_mem PVRMEM_WAM $DMESG_FILE $PID_WAM
    printf "%20s %10d %10d\n" "WebAppMgr" $PSS_WAM $PVRMEM_WAM
fi
printf "%20s %10s %10d\n" "QtWebProcess + WAM" "" $(expr $PVRMEM_QTT + $PVRMEM_WAM)

PID_SFM=$(pgrep surface-manager)
if [ ! -z $PID_SFM ]; then
    get_pss PSS_SFM $PID_SFM
    get_pvr_mem PVRMEM_SFM $DMESG_FILE $PID_SFM
    printf "%20s %10d %10d\n" "surface-manager" $PSS_SFM $PVRMEM_SFM
fi

PSS_TOTAL=$(expr $PSS_QTT + $PSS_WAM + $PSS_SFM)
PVRMEM_TOTAL=$(expr $PVRMEM_QTT + $PVRMEM_WAM + $PVRMEM_SFM)
echo ----------------------------------------------------------------------
printf "%20s %10d %10d\n" "Total" $PSS_TOTAL $PVRMEM_TOTAL
