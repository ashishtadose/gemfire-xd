#!/bin/bash
#set -xv

if [ ! -f ./cc.pid ]; then
  echo "ERROR: script expects to be at the top of your cruisecontrol area."
  exit 1
fi

logfile=chkdisk.log

exec </dev/null
exec 3>$logfile
exec 1>&3
exec 2>&3

# This script is intended to run in the top of the cruisecontrol directory 
# and clean up old artifacts to allow CC to continually run without running
# out of disk space. It has defaults that may needs to be configured to
# the disk that CC is running from. 
#
# 1) Adjust THRESHOLD to allow for double the space needed for unit tests   
#    results. CC will copy the last run to the artifacts so twice the space 
#    is needed to prevent running out of space during this action.
THRESHOLD=75

#
# 2) Depending on your available free space on the CC disk the NUMTOCLEAN
#    may need to be adjusted to allow leaving of at least one or two results
#    once the THRESHOLD is reached. 
NUMTOCLEAN=10

#
# 3) Adjust the check INTERVAL as needed.
INTERVAL=36000

#
# 4) Who to notify when a cc hang is detected
MAILTO=dickc

#
# 5) Hours to wait before sending above mail
HANGTIME=11

while ( cat cc.pid | xargs ps -p > /dev/null 2>&1 ) ; do
  date 

  # Checks for cruisecontrol hangs 
  rm -f temp.log 
  STAT=1
  stat -c%Y cruisecontrol_*.log | perl -ne '$hour=$HANGTIME; if(scalar(time())-$_ > (3600*$hour)) { exit 1;} exit 0;'
  STAT=$?
  # maybe this should be cruisecontrol.log file instead? 
  if [ $STAT -eq 0 ]; then
    if [ "x$MAILSENT" = "x" ]; then
      tail -50 cruisecontrol_*.log > temp.log
      ssh -n biwa "/usr/ucb/mail -s 'WARNING CRUISECONTROL HANG DETECTED on `hostname`' $MAILTO < `pwd`/temp.log"
      sleep 86400 # sleep for 24 hours and then what?
      MAILSENT=yes
      exit 1
    fi
  else 
    echo "Hang detection ok" 
  fi

  # Checks disk space limits
  DS=`df -k . | perl -ne 'print $1 if (/ ([0-9]+)% /);'`
  if [ "$DS" -gt "$THRESHOLD" ]; then
    date 
    echo "Disk space status"
    df -k . 
    # list oldest artifacts to log
    #echo "all artifacts"
    #ls -dtr ./artifacts/*/* 
    #echo "oldest artifacts that will be cleaned"
    #ls -dtr ./artifacts/*/* | head -$NUMTOCLEAN
    # clean oldest artifacts 
    ls -dtr ./artifacts/*/* | head -$NUMTOCLEAN | xargs rm -rf

    # list oldest logs to log
    #echo "all logs"
    #ls -dtr ./logs/*/* 
    #echo "oldest logs that will be cleaned"
    #ls -dtr ./logs/*/* | head -$NUMTOCLEAN
    # clean logs 
    # remove this when logs are equal to artifacts
    ls -dtr ./logs/*/* | head -$NUMTOCLEAN | xargs rm -f

    echo "remaining artifacts after cleaning"
    ls -dtr ./artifacts/*/* 
    echo "Disk space status"
    df -k .
    # Added to run once
    #break
  else 
    echo "Disk space below limit at $DS%"
    sleep $INTERVAL
  fi

done
