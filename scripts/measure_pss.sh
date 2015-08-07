#!/bin/bash

# 1. Show each processes
echo ps aux | grep chrome | grep -v grep
echo ======================================================================
ps aux | grep chrome | grep -v grep
echo ======================================================================

# 2. Measuring pss for each process
for PID in `pgrep chrome`
do
    echo --- start of $PID ----------------------------------------------------
    ps aux | grep $PID | grep -v grep
    echo ----------------------------------------------------------------------
    /measure_pss/find_pss.sh $PID
    echo ---   end of $PID ----------------------------------------------------
done
