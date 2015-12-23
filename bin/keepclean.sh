#!/bin/bash
# Wake up every ten minutes and remove passing hydra runs.
# This is valuable if you are running a hydra test many times and you are
# only interested in runs that fail or hang.
#
# Usage: cd $results; bash $src/bin/keepclean.sh &

while true
do
  if [ ! -e oneliner.txt ]; then
    echo "no Hydra runs to clean up"
    exit 0
  fi
  sleep 600
  passed=`grep -il "have a pleasant day" */Master*.log`
  if [ "$passed" != "" ]; then
    date
    for x in $passed
    do
      directory=`dirname $x`
      echo "rm -rf $directory"
      rm -rf $directory
    done
  fi
done
