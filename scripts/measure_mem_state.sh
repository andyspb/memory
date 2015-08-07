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

function get_rss()
{
    local __resultvar=$1
    local __proc_file="/proc/$2/smaps"
    local __rss=$(cat $__proc_file | awk '/Rss:/ {sum += $2} END { print sum }')
    eval $__resultvar="'$__rss'"
}

function get_rss_shc()
{
    local __resultvar=$1
    local __proc_file="/proc/$2/smaps"
    local __shc=$(cat $__proc_file | awk '/Shared_Clean:/ {sum += $2} END { print sum }')
    eval $__resultvar="'$__shc'"
}

function get_rss_shd()
{
    local __resultvar=$1
    local __proc_file="/proc/$2/smaps"
    local __shd=$(cat $__proc_file | awk '/Shared_Dirty:/ {sum += $2} END { print sum }')
    eval $__resultvar="'$__shd'"
}

function get_rss_prc()
{
    local __resultvar=$1
    local __proc_file="/proc/$2/smaps"
    local __prc=$(cat $__proc_file | awk '/Private_Clean:/ {sum += $2} END { print sum }')
    eval $__resultvar="'$__prc'"
}

function get_rss_prd()
{
    local __resultvar=$1
    local __proc_file="/proc/$2/smaps"
    local __prd=$(cat $__proc_file | awk '/Private_Dirty:/ {sum += $2} END { print sum }')
    eval $__resultvar="'$__prd'"
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
#echo --------------------------------------------------------------------------------------------------------------
#head -4 /proc/meminfo
#echo --------------------------------------------------------------------------------------------------------------
printf "%20s %10s %10s %10s %10s %10s %10s %10s %10s\n" "Process Name" "PID" "RSS" "PSS" "PVR_MEM" "SHC" "SHD" "PRC" "PRD"
echo ==============================================================================================================
# RSS
RSS_QTT=0
RSS_WAM=0
RSS_SFM=0
# PSS
PSS_QTT=0
PSS_WAM=0
PSS_SFM=0
# PVR
PVRMEM_QTT=0
PVRMEM_WAM=0
PVRMEM_SFM=0
# RSS_SHC
RSS_QTT_SHC=0
RSS_WAM_SHC=0
RSS_SFM_SHC=0
# RSS_SHD
RSS_QTT_SHD=0
RSS_WAM_SHD=0
RSS_SFM_SHD=0
# RSS_PRC
RSS_QTT_PRC=0
RSS_WAM_PRC=0
RSS_SFM_PRC=0
# RSS_PRD 
RSS_QTT_PRD=0
RSS_WAM_PRD=0
RSS_SFM_PRD=0

PID_QTT=$(pgrep QtWebProcess)
if [ ! -z $PID_QTT ]; then
    get_rss RSS_QTT $PID_QTT
    get_pss PSS_QTT $PID_QTT
    get_rss_shc RSS_QTT_SHC $PID_QTT
    get_rss_shd RSS_QTT_SHD $PID_QTT
    get_rss_prc RSS_QTT_PRC $PID_QTT
    get_rss_prd RSS_QTT_PRD $PID_QTT
    get_pvr_mem PVRMEM_QTT $DMESG_FILE $PID_QTT
    printf "%20s %10d %10d %10d %10d %10d %10d %10d %10d\n" "QtWebProcess" $PID_QTT $RSS_QTT $PSS_QTT $PVRMEM_QTT $RSS_QTT_SHC $RSS_QTT_SHD $RSS_QTT_PRC $RSS_QTT_PRD
fi

PID_WAM=$(pgrep WebAppMgr)
if [ ! -z $PID_WAM ]; then
    get_rss RSS_WAM $PID_WAM
    get_pss PSS_WAM $PID_WAM
    get_rss_shc RSS_WAM_SHC $PID_WAM
    get_rss_shd RSS_WAM_SHD $PID_WAM
    get_rss_prc RSS_WAM_PRC $PID_WAM
    get_rss_prd RSS_WAM_PRD $PID_WAM
    get_pvr_mem PVRMEM_WAM $DMESG_FILE $PID_WAM
    printf "%20s %10d %10d %10d %10d %10d %10d %10d %10d\n" "WebAppMgr" $PID_WAM $RSS_WAM $PSS_WAM $PVRMEM_WAM $RSS_WAM_SHC $RSS_WAM_SHD $RSS_WAM_PRC $RSS_WAM_PRD
fi
if [ ! -z $PID_QTT ]; then
    printf "%20s %10s %10d %10d %10d\n" "QtWebProcess + WAM" "" $(expr $RSS_QTT + $RSS_WAM) $(expr $PSS_QTT + $PSS_WAM) $(expr $PVRMEM_QTT + $PVRMEM_WAM)
fi

PID_SFM=$(pgrep surface-manager)
if [ ! -z $PID_SFM ]; then
    get_rss RSS_SFM $PID_SFM 
    get_pss PSS_SFM $PID_SFM
    get_rss_shc RSS_SFM_SHC $PID_SFM
    get_rss_shd RSS_SFM_SHD $PID_SFM
    get_rss_prc RSS_SFM_PRC $PID_SFM
    get_rss_prd RSS_SFM_PRD $PID_SFM
    get_pvr_mem PVRMEM_SFM $DMESG_FILE $PID_SFM
    printf "%20s %10d %10d %10d %10d %10d %10d %10d %10d\n" "surface-manager" $PID_SFM $RSS_SFM $PSS_SFM $PVRMEM_SFM $RSS_SFM_SHC $RSS_SFM_SHD $RSS_SFM_PRC $RSS_SFM_PRD
fi

RSS_TOTAL=$(expr $RSS_QTT + $RSS_WAM + $RSS_SFM)
PSS_TOTAL=$(expr $PSS_QTT + $PSS_WAM + $PSS_SFM)
PVRMEM_TOTAL=$(expr $PVRMEM_QTT + $PVRMEM_WAM + $PVRMEM_SFM)
echo --------------------------------------------------------------------------------------------------------------
printf "%20s %10d %10d %10d\n\n" "Total" $RSS_TOTAL $PSS_TOTAL $PVRMEM_TOTAL
