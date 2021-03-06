#!/bin/bash
# find RSS, PSS for QtWebProcess
# show top memory eaters from /proc/<PID>/smaps
PID=$(pgrep QtWebProcess | head -1)
LIMIT=30

if [ $# -gt 2 ]; then
    PID="$1"
fi

if [ -z $PID ]; then
    echo "No PID found. $PID"
    exit -1
fi

PROC_FILE="/proc/${PID}/smaps"
date
echo "Looking for RSS, PSS memory consumption for QtWebProcess"
echo "From: $PROC_FILE"
# Get total of them
cat $PROC_FILE | awk '/Size:/ {sum_size += $2} /Rss:/ {sum_rss += $2} /Pss:/ {sum_pss += $2} END { printf "Total:\t\t\tSize: %d K, Rss: %d K, Pss: %d K\n", sum_size, sum_rss, sum_pss }'

# http://stackoverflow.com/questions/2787241/smaps-un-named-segment-of-memory
# As I mentioned in the answer, the mapping marked as "[heap]" is just indicating a special anonymous mapping - the one that is manipulated by the brk() system call. 
# This used to be the way that malloc() always acquired memory - but these days, malloc() often creates a new anonymous mapping (as you've seen in your example). 
# Small allocations (eg a few hundred bytes) made with malloc() will likely be made within the [heap] mapping.

# let's count all the 0 files came from mmap() in TCMalloc
cat $PROC_FILE | awk 'NF > 3 { f = $NF } $1 ~ /Pss:/ && f == 0 { pss_0 += $2 } END { printf "%-70s %6d K\n", "Maybe malloc(inode 0): ", pss_0 }'

# for item in Size Rss Pss
for item in Pss
do
    echo "============================== $item =============================="
    cat $PROC_FILE | awk -v item=${item} 'NF > 3 { f = $NF } $1 ~ /^'${item}:'/ && f ~ /(\/|\[)/ { printf "%-70s %6d K\n", f, $2 } ' | sort -nr -k2,2 | head -${LIMIT}
done

