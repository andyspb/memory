#!/bin/bash
# find RSS, PSS for QtWebProcess
# show top memory eaters from /proc/<PID>/smaps
# kill myapp if its already running 

MYAPP="com.palm.app.myapp"
BAREMOON="com.palm.app.baremoon"
QTWEBPROCESS="QtWebProcess"
WEBAPPMGR="WebAppMgr"


PrintHeader() {
  date
  #printf "Processes RSS, PSS, Heap, Stack, Data memory consumption\n"
  printf "%-14s | %-7s | %-12s | %-10s (%-8s %-8s %-8s %-8s) | %-10s | %-10s | %-10s | %-10s | %-10s\n" "Process" "PID" "Total (kB)" "Rss (kB)" "SHC," "SHD," "PRC," "PRD" "Pss (kB)" "VmSize (kB)" "VmData (kB)" "VmStk (kB)" "VmExe (kB)"
}

PrintHorisontalDelimeter() {
  head -c $1 < /dev/zero | tr '\0' '-' 
  printf "\n" 
} 

MemoryUsage() {
  #echo "$1:"
  PrintHorisontalDelimeter 160
  local process=$1
  local pid=$(pgrep ${process} | head -1)
  if [ -z ${pid} ]; then
      echo "ERROR: No PID found for ${process}. ${pid}"
      exit -1
  fi
  local proc_file="/proc/${pid}/smaps"
  local temp_file="/var/log/${process}.mem.log" 
  rm -rf ${temp_file} | touch ${temp_file}
  #echo "For ${process} from: ${proc_file}"
  # Get total of them
  cat $proc_file | awk '/Size:/ {sum_size += $2} /Rss:/ {sum_rss += $2} /Pss:/ {sum_pss += $2} /Shared_Clean:/ {sum_shared_clean +=$2} /Shared_Dirty:/ {sum_shared_dirty += $2} /Private_Clean:/ {sum_private_clean += $2} /Private_Dirty:/ {sum_private_dirty += $2} END { printf "Total: Size: %d kB, Rss: %d kB, Pss: %d kB, Shared [clean: %d kB, dirty: %d kb], Private [clean: %d kB, dirty %d kB\n", sum_size, sum_rss, sum_pss, sum_shared_clean, sum_shared_dirty, sum_private_clean, sum_private_dirty }' > ${temp_file}
  # cat ${temp_file}
  #                                                  Total       Rss       Shc         Shd         Prc         Prd         Pss   
  local mem=$(cat ${temp_file} | grep 'Total:'| awk '{print $3} {print $6} {print $13} {print $16} {print $20} {print $23} {print $9}')
  # echo ${mem[*]}
  # debug
  #local total=$(cat ${temp_file} | grep 'Total:'| awk '{print $3}')
  #local rss=$(cat ${temp_file} | grep 'Total:'| awk '{print $6}')
  #local pss=$(cat ${temp_file} | grep 'Total:'| awk '{print $9}')
  #echo "Total: " ${total} " kB" 
  #echo "RSS: " ${rss}  " kB"
  #echo "PSS: " ${pss}  " kB"

  #cat /proc/${PID_QTWEBPROCESS}/stat
  local heap=$(awk '{print $23/1024}' /proc/${pid}/stat)
  #echo "Heap: " ${heap} " kB"
  # http://man7.org/linux/man-pages/man5/proc.5.html
  local proc_status_file="/proc/${pid}/status"
  #cat ${proc_status_file}
  
  #cat ${proc_status_file} | awk '/VmData:/ {data = $2} /VmStk:/ {stack = $2} /VmExe:/ {text = $2} END { print data print stack print text }'
  local temp_str=$(cat ${proc_status_file} | awk '/VmData:/ {data = $2} /VmStk:/ {stack = $2} /VmExe:/ {text = $2} END { print data, stack, text }')
  read -a mem_status <<< "${temp_str}"
  # echo "mem_status: " 
  # echo ${mem_status[0]} 
  #echo ${mem_status[1]} 
  #echo ${mem_status[2]}
  #local data=$(cat ${proc_status_file} | grep 'VmData:'| awk '{print $2}')
  #echo "DATA segment " ${data} " kB"
  #local stack=$(cat ${proc_status_file} | grep 'VmStk:'| awk '{print $2}')
  #echo "Stack segment " ${stack} " kB"
  #local text=$(cat ${proc_status_file} | grep 'VmExe:'| awk '{print $2}')
  #echo "Text segment " ${text} " kB"
  #print resulti
  printf "%-14s | %-7d | %-12d | %-10d (%-8d %-8d %-8d %-8d) | %-10d | %-11d | %-11d | %-10d | %-11d\n" ${process} ${pid} ${mem[0]} ${mem[1]} ${mem[2]} ${mem[3]} ${mem[4]} ${mem[5]} ${mem[6]} ${heap} ${mem_status[0]}  ${mem_status[1]} ${mem_status[2]}

}

TestMemoryUsage() {
local app=$1
#echo $app
echo "Stopping WebAppMgr"
stop WebAppMgr-compositor > /dev/null 2>&1
sleep 3
echo "Starting WebAppMgr"
start WebAppMgr-compositor > /dev/null 2>&1
sleep 5
printf "No running WAM applications. QtWebProcess is not available.\n"
PrintHeader
MemoryUsage $WEBAPPMGR
#MemoryUsage $QTWEBPROCESS
PrintHorisontalDelimeter 160
sleep 10
luna-send -n 1 palm://com.palm.applicationManager/closeByAppId '{"id": "'$app'"}' > /dev/null 2>&1
sleep 15
printf "Running %s application ...\n" $1
luna-send -n 1 palm://com.webos.applicationManager/launch '{"id": "'$app'"}' > /dev/null 2>&1
sleep 3

PrintHeader
MemoryUsage $QTWEBPROCESS
MemoryUsage $WEBAPPMGR

sleep 5 
luna-send -n 1 palm://com.palm.applicationManager/closeByAppId '{"id":"'$app'"}' > /dev/null 2>&1

PrintHorisontalDelimeter 160
printf "\n"

}

printf "Processes RSS, PSS, Heap, Stack, Data memory consumption\n"
TestMemoryUsage ${MYAPP}
TestMemoryUsage ${BAREMOON}




