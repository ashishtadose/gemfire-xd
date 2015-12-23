#!/bin/bash
SCRIPTDIR=`/usr/bin/dirname $0`
OLDPWD=$PWD
cd $SCRIPTDIR
export SCRIPTDIR=$PWD
cd $OLDPWD

# Spawn a build.sh process bound to a specific processor.
# On Solaris & AIX the existing process is bound then build.sh is run.
# This means that if anything prevents the remaineder of the script from 
# runnning you will be left with a "tainted" shell.
# On Windows & Linux a new process is spawned, bound, and then build.sh is run. 
# This script makes a best effort, keep in mind that the sematics and
# guarantees of process binding vary on each platform.

if [ `uname` = "SunOS" ]; then
  cpu=`/usr/sbin/psrinfo | head -1 | awk '{print $1}'`
  /usr/sbin/pbind -b $cpu $$
  if [ "x$?" != "x0" ]; then
    echo "Error: pbind returned $?, while binding to $cpu for process $$"
    exit 1
  fi
  $SCRIPTDIR/build.sh $@
  /usr/sbin/pbind -u $$
elif [ `uname` = "Linux" ]; then
  cpu=1
  taskset $cpu $SCRIPTDIR/build.sh $@ 
  if [ "x$?" != "x0" ]; then
    echo "Error: taskset returned $?, while binding to $cpu for process $$"
    exit 1
  fi
elif uname | grep -i '^CYGWIN'  >/dev/null 2>/dev/null; then
  cmd.exe /C START /AFFINITY 1 bash.exe $SCRIPTDIR/build.sh $@ 
elif [ `uname` = "AIX" ]; then
  cpu=0
  /usr/sbin/bindprocessor $$ $cpu 
  if [ "x$?" != "x0" ]; then
    echo "Error: taskset returned $?, while binding to $cpu for process $$"
    exit 1
  fi
  $SCRIPTDIR/build.sh $@
  /usr/sbin/bindprocessor -u $$
else 
  echo "Error: unsupported platform"
  exit 1
fi
